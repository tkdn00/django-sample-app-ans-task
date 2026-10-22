FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY requirements.txt .

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt gunicorn==23.0.0


FROM python:3.12-slim


ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    WEB_CONCURRENCY=2

RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq5 libcurl4 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 appuser

COPY --from=builder /opt/venv /opt/venv/
WORKDIR /app
COPY . .

RUN python manage.py compress \
    && python manage.py collectstatic --noinput \
    && python -m compileall -q /app

USER appuser
EXPOSE 8000


CMD ["sh", "-c", "python manage.py migrate --noinput && exec gunicorn hc.wsgi:application --bind 0.0.0.0:8000 --access-logfile - --timeout 60"]