# Local Development with Docker Compose

This guide explains how to run the Django application (Healthchecks) locally with Docker Compose, what steps were taken to set it up, and why Docker Compose is used for local development.

---

## Overview

The local environment consists of two services:

| Service | Image | Purpose |
|---|---|---|
| `postgres` | `postgres:18` | PostgreSQL database, data persisted in a named volume |
| `web` | built from `terraform-aws-ecs-fargate/Dockerfile` | Django application served by Gunicorn on port 8000 |

It is the same image and the same database engine used in production (ECS Fargate + RDS PostgreSQL), so the application behaves locally the same way it does in AWS.

---

## How the setup was built

1. **Reused the production Dockerfile.** The `web` service builds from the same Dockerfile that is pushed to ECR. There is no separate "dev" image, which avoids differences between local and production environments.

2. **Set the build context to the repository root.** The Dockerfile lives in `terraform-aws-ecs-fargate/`, but it copies the application code and `requirements.txt` from the repository root. Therefore `context: .` points to the root and `dockerfile:` points to the file inside the Terraform folder. Files that must not end up in the image (Terraform state, `.git`, etc.) are excluded by `.dockerignore`.

3. **Added a PostgreSQL service.** The application switches from SQLite to PostgreSQL when `DB=postgres` is set. The database container and the application read their credentials from the same `.env` file, so `DB_NAME`/`DB_USER`/`DB_PASSWORD` always match `POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD`.

4. **Connected services by name.** Compose puts both services on a shared network where they resolve each other by service name. That is why `DB_HOST=postgres` and not `localhost` (inside a container, `localhost` is the container itself).

5. **Persisted database data.** The `postgres_data` named volume keeps the data between restarts. The mount path is `/var/lib/postgresql`, as required by the `postgres:18` image.

6. **Fixed the startup order.** The application runs database migrations on start. A plain `depends_on` only waits for the database container to start, not for PostgreSQL to accept connections, so migrations would fail with `connection refused`. A `pg_isready` healthcheck on the database and `condition: service_healthy` on the application solve this.

---

## Why Docker Compose for local development

- **One command to start everything.** `docker compose up` builds the image, starts the database and the application, and wires them together. No need to install Python, PostgreSQL, `libpq` or `libcurl` on the host.
- **Same environment for everyone.** Every teammate runs the same Python version, the same system libraries and the same database version, regardless of their OS. "Works on my machine" issues disappear.
- **Close to production.** The same image and the same database engine as in AWS, so most problems are caught locally before deployment.
- **Isolation.** Each project runs in its own containers and network. Nothing conflicts with other projects or with software installed on the host.
- **Configuration as code.** The environment is described in `docker-compose.yml` and versioned in Git. Changes to the setup are reviewed like any other code.
- **Easy reset.** A clean environment with an empty database is one command away (`docker compose down -v`).

---

## Files

### `docker-compose.yml`

```yaml
services:
  postgres:
    image: postgres:18
    env_file:
      - ./.env
    volumes:
      - postgres_data:/var/lib/postgresql
    healthcheck:
      test: pg_isready -U postgres
      interval: 5s
      timeout: 5s
      retries: 5

  web:
    build:
      context: .
      dockerfile: ./terraform-aws-ecs-fargate/Dockerfile
    ports:
      - 8000:8000
    env_file:
      - ./.env
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
```

### `.env`

Not committed to Git. Each teammate creates it from `.env.example`:

```dotenv
# app
DB=postgres
DB_HOST=postgres
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=postgres
SECRET_KEY=change-me
ALLOWED_HOSTS=localhost,127.0.0.1

# postgres
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

| Variable | Purpose |
|---|---|
| `DB=postgres` | Switches the application from SQLite to PostgreSQL. Without it, all `DB_*` variables are ignored |
| `DB_HOST` | Name of the database service in Compose |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Must match `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `SECRET_KEY` | Django key for signing sessions and CSRF tokens. Without it the app falls back to an insecure default |
| `ALLOWED_HOSTS` | Hosts Django accepts requests for. Without `127.0.0.1`, opening `http://127.0.0.1:8000` returns 400 |
| `POSTGRES_*` | Used by the database image to create the database and user on first start |

---

## Getting started (for teammates)

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine with the Compose plugin)
- Git

The image builds natively for your machine's architecture, so it works on both Apple Silicon and x86.

### 1. Clone the repository

```bash
git clone <repository-url>
cd <repository-folder>
```

### 2. Create the `.env` file

```bash
cp .env.example .env
```

Generate a secret key and put it into `SECRET_KEY` in `.env`:

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

### 3. Start the environment

```bash
docker compose up -d --build
```

The first build takes a few minutes (dependencies are compiled). Subsequent starts are fast thanks to the layer cache.

### 4. Check that everything is running

```bash
docker compose ps
```

`postgres` should be `healthy` and `web` should be `running`. Then check the application and the database connection:

```bash
curl http://localhost:8000/api/v3/status/
```

The response `OK` means the application is up and connected to PostgreSQL.

### 5. Create a user

The database starts empty and there are no default credentials. Create an account:

```bash
docker compose exec web python manage.py createsuperuser --email admin@example.com --password <your-password>
```

Registration through the website does not work locally: it sends a login link by email, and no SMTP server is configured.

### 6. Open the application

- Application: http://localhost:8000/accounts/login/
- Django admin: http://localhost:8000/admin/

---

## Everyday commands

| Task | Command |
|---|---|
| Start in the background | `docker compose up -d` |
| Rebuild after code or dependency changes | `docker compose up -d --build` |
| Follow application logs | `docker compose logs -f web` |
| Stop containers (data is kept) | `docker compose down` |
| Stop and delete all data | `docker compose down -v` |
| Open a shell in the application container | `docker compose exec web sh` |
| Run a Django management command | `docker compose exec web python manage.py <command>` |
| Open a PostgreSQL console | `docker compose exec postgres psql -U postgres` |

The application code is baked into the image, so code changes require a rebuild (`docker compose up -d --build`).

---

## Troubleshooting

**`web` exits right after start.** Check `docker compose logs web`. A database connection error usually means the values in `.env` do not match between the `DB_*` and `POSTGRES_*` variables.

**Changed database credentials in `.env`, but the app cannot connect.** PostgreSQL applies `POSTGRES_*` variables only when the volume is initialized for the first time. Recreate the volume (this deletes local data):

```bash
docker compose down -v
docker compose up -d
```

**`400 Bad Request` in the browser.** The host you used is not in `ALLOWED_HOSTS`. Use `http://localhost:8000` or add the host to `.env`.

**Port 8000 is already in use.** Change the published port, e.g. `8080:8000`, and set `SITE_ROOT=http://localhost:8080` in `.env` so the links generated by the application use the correct port.

**`email ... is already taken` when creating a user.** The user already exists. Log in with it or use a different email.