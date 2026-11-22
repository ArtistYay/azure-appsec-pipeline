import json  # converts python dictionaries to JSON strings for logging
import logging  # built in logging module, writes log entries to stdout/stderr

from flask import Flask, request  # Flask creates the web app, request holds the incoming HTTP request

logger = logging.getLogger(__name__)
# log INFO and above, and only output the message itself (the message is already JSON)
logging.basicConfig(level=logging.INFO, format="%(message)s")

app = Flask(__name__)  # create a Flask app instance

MAX_USER_AGENT_LENGTH = 200  # user agents are attacker-controlled, so cap how much we store


def get_client_ip():
    """Return the caller's IP address as seen by the Container Apps ingress.

    Container Apps sits behind a proxy (Envoy), so request.remote_addr is the proxy,
    not the real caller. The proxy APPENDS the address it actually saw to the end of
    the X-Forwarded-For header. Anything earlier in that header was sent by the client
    and can be faked, so we only trust the LAST value.
    """
    forwarded_for = request.headers.get("X-Forwarded-For", "")
    if forwarded_for:
        return forwarded_for.split(",")[-1].strip()
    return request.remote_addr


def log_event(event, status):
    """Write one structured JSON log line. Sentinel turns each key into a queryable column."""
    logger.info(
        json.dumps(
            {
                "event": event,
                "path": request.path,
                "method": request.method,
                "status": status,
                "client_ip": get_client_ip(),
                "user_agent": request.headers.get("User-Agent", "")[:MAX_USER_AGENT_LENGTH],
            }
        )
    )


@app.route("/health", methods=["GET"])  # only GET is allowed on this route
def status_message():
    log_event("health_check", 200)
    return {
        "status": "healthy",
        "message": "azure-appsec-pipeline is running",
    }


@app.errorhandler(404)
def not_found(error):
    # someone asked for a path that doesn't exist, lots of these from one IP looks like recon/scanning
    log_event("not_found", 404)
    return {"error": "not found"}, 404


@app.errorhandler(405)
def method_not_allowed(error):
    # someone used the wrong HTTP method (e.g. POST /health), a classic method tampering probe
    log_event("method_not_allowed", 405)
    return {"error": "method not allowed"}, 405


if __name__ == "__main__":
    # local development only. In the container, Gunicorn starts the app (see Dockerfile).
    # Binding to 0.0.0.0 is intentional so Docker port mapping works.
    app.run(host="0.0.0.0", port=5000)  # nosec B104
