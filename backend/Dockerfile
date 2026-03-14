# ── Stage 1: dependency builder ──────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build tools needed for some Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies into an isolated directory (not system-wide)
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: production runtime ───────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# Security: run as non-root user
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home appuser

WORKDIR /app

# Copy only the installed packages from builder — no gcc, no pip, no cache
COPY --from=builder /install /usr/local

# Copy application source
COPY --chown=appuser:appgroup ./app ./app

USER appuser

EXPOSE 8000

# Gunicorn with uvicorn workers — production-grade ASGI server
# Workers = (2 x CPU cores) + 1 is the standard formula; 2 is safe for EKS t3.small
CMD ["python", "-m", "uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "2", \
     "--no-access-log"]