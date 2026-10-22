# Docker Image Optimization for the Django Application

This document describes how the Docker image of the application (Healthchecks, Django 6.1, Python 3.12) deployed to AWS ECS Fargate (ARM64) was optimized. It compares the first Dockerfile with the optimized one and explains each change and why it makes the image smaller or the build faster.

---

## Background

The very first build copied far more than the application needed. The repository root had no `.dockerignore`, so `COPY . .` copied everything into the image: `.terraform/` with the AWS provider binary, `.git`, `ansible/` and even `terraform.tfstate` containing secrets. Adding a `.dockerignore` made the image several times smaller and removed the secrets from it. The optimization below starts from that version.

---

## What changed and why

### 1. Cleaning up dependencies in the builder stage

**Problem.** The Python packages layer is the largest layer added on top of the base image, and a significant part of it is never used at runtime.

**Solution.** After `pip install`, the builder stage removes what is not needed:

```dockerfile
RUN pip uninstall -y pip setuptools \
    && find /opt/venv \( -name '*.po' -o -name '*.mo' -o -name '*.pyi' \) -delete \
    && find /opt/venv -type d -name tests -prune -exec rm -rf {} +
```

| What is removed | Why it is safe |
|---|---|
| `pip`, `setuptools` | Only needed to install packages; nothing is installed at runtime |
| `*.po`, `*.mo` (Django translations) | `hc/settings.py` sets `USE_I18N = False`, so Django never reads these files |
| `*.pyi`, third-party `tests/` | Type stubs and library tests are only used during development |

**Why in the builder stage.** Every Dockerfile instruction creates an immutable layer. If the files were deleted in the final stage after `COPY`, they would remain in the previous layer and the image size would not change. Deleting them in the builder stage guarantees that the final image receives an already cleaned virtualenv.

### 2. Extended `.dockerignore`

Development-only files were added to the exclusions:

```
stuff                  # Bootstrap and icon sources
hc/**/tests            # application tests
hc/test.py
requirements-dev.txt
mypy.ini
```

This keeps files that are never used at runtime out of the image and makes the build context sent to the Docker daemon smaller. `CHANGELOG.md` is intentionally **not** excluded: `settings.py` reads the application version from it at startup.

### 3. Virtualenv instead of `--prefix`

**Before:** `pip install --prefix=/install`, then `COPY --from=builder /install /usr/local`. Packages were mixed with the image's system Python.
**After:** a dedicated `/opt/venv` environment copied as a single directory. The structure is cleaner, and the cleanup from item 1 affects only the application's dependencies.

### 4. Faster builds: pip cache and layer order

```dockerfile
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt gunicorn==23.0.0
```

- **Layer order.** `requirements.txt` is copied and dependencies are installed **before** the code is copied. When only the code changes, Docker reuses every cached layer up to `COPY . .` and rebuilds only the code and static files.
- **BuildKit cache mount.** When `requirements.txt` changes, previously downloaded packages are taken from the local cache instead of PyPI. The cache itself is not stored in the image, so `--no-cache-dir` is no longer needed.

### 5. Reliability and security

| Change | Why |
|---|---|
| `exec gunicorn` in `CMD` | Gunicorn becomes PID 1 and receives SIGTERM from ECS. Previously `sh` received the signal and did not forward it, so ECS force-killed the container after a timeout and in-flight requests were dropped |
| Code copied without `--chown=appuser` | The code is owned by root, so the application process can read it but not modify it |
| User with a fixed UID `10001` | Predictable file permissions, easier to use with security policies |
| `gunicorn==23.0.0` | A pinned version makes the build reproducible |
| `WEB_CONCURRENCY` instead of `--workers 3` | The number of workers is set in the task definition to match the task's CPU, without rebuilding the image |
| `--access-logfile -` | Access logs go to stdout and end up in CloudWatch |
| `python -m compileall` | `.pyc` files are compiled at build time instead of on every container start |

---

## Dockerfile comparison

<details>
<summary>First version</summary>

```dockerfile
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt gunicorn


FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBUG=False \
    DB=postgres

RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq5 libcurl4 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home appuser

COPY --from=builder /install /usr/local

WORKDIR /app
COPY --chown=appuser:appuser . .

RUN python manage.py compress && python manage.py collectstatic --noinput

USER appuser
EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn hc.wsgi:application --bind 0.0.0.0:8000 --workers 3"]
```
</details>

<details>
<summary>Optimized version</summary>

```dockerfile
# syntax=docker/dockerfile:1

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

RUN pip uninstall -y pip setuptools \
    && find /opt/venv \( -name '*.po' -o -name '*.mo' -o -name '*.pyi' \) -delete \
    && find /opt/venv -type d -name tests -prune -exec rm -rf {} +


FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    WEB_CONCURRENCY=2 \
    DEBUG=False

RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq5 libcurl4 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 appuser

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY . .

RUN python manage.py compress \
    && python manage.py collectstatic --noinput \
    && python -m compileall -q /app

USER appuser
EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate --noinput && exec gunicorn hc.wsgi:application --bind 0.0.0.0:8000 --access-logfile - --timeout 60"]
```
</details>

---

## How to build

The build runs from the `terraform-aws-ecs-fargate/` directory, with the repository root as the build context:

```bash
docker build --platform linux/arm64 -f Dockerfile -t djangoapp-optimized:v2 ../
```

---

## Next steps

These optimizations were left out of the current version because they require more changes and separate testing:

- **Alpine base image** (`python:3.12-alpine`). The base image is considerably smaller than `slim`. However, Alpine uses musl instead of glibc, so some packages have to be compiled and the application's behavior needs to be verified separately.
- **uv instead of pip.** Packages install many times faster, which significantly shortens cold builds.
- **Migrations as a separate ECS task.** Currently `migrate` runs at the start of every container. Once there is more than one task, migrations should run once before deployment (`aws ecs run-task`) to avoid concurrent execution.
- **Multi-architecture build** (`docker buildx --platform linux/arm64,linux/amd64`). A single tag would then run on both Graviton and x86.