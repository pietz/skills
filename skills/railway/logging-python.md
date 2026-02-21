# Python Logging for Railway

Railway parses single-line JSON on stdout and uses the `level` field for color-coding (`info` = blue, `warning` = yellow, `error` = red). Every JSON field becomes queryable in the [Log Explorer](https://docs.railway.com/observability/logs) via `@field:value`.

**Without structured JSON logging**, Python's `logging` module writes to stderr, which Railway renders entirely in red as errors.

## Setup

```bash
uv add python-json-logger
```

```python
import contextvars
import logging
import sys
from pythonjsonlogger.json import JsonFormatter

# Optional: context variable for correlation IDs (see "Correlation IDs" below)
request_id_var: contextvars.ContextVar[str | None] = contextvars.ContextVar("request_id", default=None)

class RailwayJsonFormatter(JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record["level"] = record.levelname.lower()
        # Inject correlation ID if set
        rid = request_id_var.get()
        if rid is not None:
            log_record["request_id"] = rid

def setup_logging():
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(RailwayJsonFormatter("{message}", style="{"))
    logging.basicConfig(handlers=[handler], level=logging.INFO, force=True)

    # Silence noisy third-party libraries
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access", "httpx", "httpcore", "sqlalchemy"):
        logging.getLogger(name).setLevel(logging.CRITICAL)
```

Call `setup_logging()` at app startup **before** any other module creates loggers. Using `force=True` overrides handlers that libraries may have already installed.

Set `PYTHONUNBUFFERED=1` as an env var in Railway to prevent buffered stdout from delaying log delivery.

## Structured Fields

Pass domain context via `extra={}` — never bake it into the message string:

```python
logger.info("Search completed", extra={"vector_results": 50, "after_filter": 10})
# → {"message": "Search completed", "level": "info", "vector_results": 50, "after_filter": 10}
```

These fields are queryable in Railway's Log Explorer: `@vector_results:50`, `@after_filter:>5`, etc.

## Log Level Conventions

| Level | When | Examples |
|---|---|---|
| `info` | Normal operations | Request served, record indexed, search completed |
| `warning` | Expected but notable conditions, client errors | 404 not found, auth token refreshed, data parse failure |
| `error` | Server failures needing attention | Unhandled exception, external service down |
| `exception` | Inside `except` blocks (auto-captures traceback) | Failed API call, timeout in background task |

Don't use `debug` in production — it creates noise and eats into Railway's 500 lines/sec/replica rate limit.

## Request Logging Middleware

Log one line per HTTP request in middleware rather than scattering log calls across route handlers:

```python
class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        ms = (time.perf_counter() - start) * 1000

        extra = {"method": request.method, "path": request.url.path,
                 "status": response.status_code, "duration_ms": round(ms)}
        # Let route handlers inject domain context
        extra.update(getattr(request.state, "log_extra", {}))

        log = logger.error if response.status_code >= 500 else \
              logger.warning if response.status_code >= 400 else logger.info
        log(f"{request.method} {request.url.path} {response.status_code}", extra=extra)
        return response
```

Route handlers attach context without coupling to logging:

```python
request.state.log_extra = {"role_id": role_id, "matched": len(results)}
```

## Correlation IDs

Use `contextvars` to propagate a correlation ID through async call chains without threading it through every function signature:

```python
request_id_var.set(event_id)  # set once at the entry point
# Every logger.info/warning/error downstream automatically includes "request_id"
```

This is async-safe — concurrent tasks don't bleed IDs into each other. The formatter picks it up automatically (see setup above).

## Exception Logging

- **Log and swallow**: `logger.exception("msg")` — inside `except`, logs with traceback, does not re-raise.
- **Log and re-raise**: `logger.exception("msg")` followed by `raise` — when the caller needs to handle it.
- **Middleware catch**: catch unhandled exceptions, log with `extra={"traceback": traceback.format_exc()}`, then re-raise for FastAPI's error handler.

## Silencing Third-Party Libraries

Set noisy libraries to `CRITICAL` in `setup_logging()`. Common candidates: `uvicorn`, `uvicorn.access`, `httpx`, `httpcore`, `sqlalchemy`, `asyncpg`, `openai`, `google`, `grpc`, `pydantic_ai`.

## Querying Logs in Railway

The Log Explorer supports: `@field:value`, `"exact phrase"`, `AND`/`OR`/`-` (negation), numeric ranges (`@duration_ms:>500`, `@httpStatus:500..599`), and grouping with `()`. See [Railway log query docs](https://docs.railway.com/observability/logs).

## Common Pitfalls

| Problem | Cause | Fix |
|---|---|---|
| All logs appear red | Python logging defaults to stderr | Use `StreamHandler(sys.stdout)` |
| `extra={}` fields missing | Default formatter ignores extra | Use `python-json-logger` |
| Logs delayed or missing | stdout buffering in containers | Set `PYTHONUNBUFFERED=1` |
| Stack traces split across lines | Multi-line plaintext output | Serialize into a single JSON field |
| Logs silently dropped | >500 lines/sec/replica | Suppress debug, avoid logging in loops |
| PostgreSQL INFO = red errors | PG writes INFO to stderr | Custom start command: see below |

### PostgreSQL Log Noise

PostgreSQL INFO messages appear as errors in Railway. Fix with a custom start command in the database service settings:

```
/bin/sh -c "unset PGPORT; exec docker-entrypoint.sh postgres --port=5432 -c log_min_messages=warning -c log_statement=none 2>&1"
```
