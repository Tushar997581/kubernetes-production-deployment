import os
import time
from contextlib import contextmanager
from threading import Lock
from flask import Flask, jsonify, render_template, request
import psycopg2
from psycopg2.extras import RealDictCursor
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

APP_NAME = os.getenv("APP_NAME", "DevOps Task Manager")
APP_ENV = os.getenv("APP_ENV", "development")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
SECRET_KEY = os.getenv("APP_SECRET_KEY", "local-demo-only-change-me")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.getenv("DB_NAME", "taskmanager"),
    "user": os.getenv("DB_USER", "taskmanager"),
    "password": os.getenv("DB_PASSWORD", ""),
    "connect_timeout": 3,
}

app = Flask(__name__)
app.config["SECRET_KEY"] = SECRET_KEY

REQUEST_COUNT = Counter("taskmanager_http_requests_total", "Total HTTP requests handled", ["method", "endpoint", "http_status"])
REQUEST_LATENCY = Histogram("taskmanager_http_request_duration_seconds", "HTTP request duration in seconds", ["endpoint"])

_schema_ready = False
_schema_lock = Lock()

@contextmanager
def db_connection():
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def ensure_schema():
    global _schema_ready
    if _schema_ready:
        return
    with _schema_lock:
        if _schema_ready:
            return
        with db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("CREATE TABLE IF NOT EXISTS tasks (id BIGSERIAL PRIMARY KEY, title VARCHAR(120) NOT NULL, done BOOLEAN NOT NULL DEFAULT FALSE)")
                cursor.execute("INSERT INTO tasks (id, title, done) VALUES (%s, %s, %s) ON CONFLICT (id) DO NOTHING", (1, "Deploy application to Kubernetes", False))
                cursor.execute("INSERT INTO tasks (id, title, done) VALUES (%s, %s, %s) ON CONFLICT (id) DO NOTHING", (2, "Configure health probes", True))
                cursor.execute("SELECT setval(pg_get_serial_sequence($$tasks$$, $$id$$), GREATEST((SELECT COALESCE(MAX(id), 1) FROM tasks), 1), true)")
        _schema_ready = True

@app.before_request
def start_timer():
    request._start_time = time.time()

@app.after_request
def record_metrics(response):
    endpoint = request.url_rule.rule if request.url_rule else "unmatched"
    REQUEST_COUNT.labels(request.method, endpoint, str(response.status_code)).inc()
    REQUEST_LATENCY.labels(endpoint).observe(time.time() - getattr(request, "_start_time", time.time()))
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    return response

@app.get("/")
def home():
    return render_template("index.html", app_name=APP_NAME, environment=APP_ENV, version=APP_VERSION)

@app.get("/api/tasks")
def list_tasks():
    try:
        ensure_schema()
        with db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT id, title, done FROM tasks ORDER BY id")
                tasks = [dict(row) for row in cursor.fetchall()]
        return jsonify(tasks)
    except psycopg2.Error:
        app.logger.exception("Database error while listing tasks")
        return jsonify({"error": "database temporarily unavailable"}), 503

@app.post("/api/tasks")
def create_task():
    data = request.get_json(silent=True) or {}
    title = str(data.get("title", "")).strip()
    if not title:
        return jsonify({"error": "title is required"}), 400
    try:
        ensure_schema()
        with db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("INSERT INTO tasks (title) VALUES (%s) RETURNING id, title, done", (title[:120],))
                task = dict(cursor.fetchone())
        return jsonify(task), 201
    except psycopg2.Error:
        app.logger.exception("Database error while creating task")
        return jsonify({"error": "database temporarily unavailable"}), 503

@app.patch("/api/tasks/<int:task_id>")
def update_task(task_id):
    data = request.get_json(silent=True) or {}
    try:
        ensure_schema()
        with db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                if "done" in data:
                    cursor.execute("UPDATE tasks SET done = %s WHERE id = %s RETURNING id, title, done", (bool(data["done"]), task_id))
                else:
                    cursor.execute("SELECT id, title, done FROM tasks WHERE id = %s", (task_id,))
                task = cursor.fetchone()
                if task is None:
                    return jsonify({"error": "task not found"}), 404
                task = dict(task)
        return jsonify(task)
    except psycopg2.Error:
        app.logger.exception("Database error while updating task")
        return jsonify({"error": "database temporarily unavailable"}), 503

@app.get("/health/live")
def liveness():
    return jsonify({"status": "alive"}), 200

@app.get("/health/ready")
def readiness():
    try:
        ensure_schema()
        with db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
        return jsonify({"status": "ready"}), 200
    except psycopg2.Error:
        app.logger.warning("Readiness check failed: database unavailable")
        return jsonify({"status": "not_ready", "reason": "database unavailable"}), 503

@app.get("/info")
def info():
    return jsonify({"application": APP_NAME, "environment": APP_ENV, "version": APP_VERSION})

@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

@app.errorhandler(404)
def not_found(_error):
    return jsonify({"error": "not found"}), 404

@app.errorhandler(500)
def server_error(_error):
    return jsonify({"error": "internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
