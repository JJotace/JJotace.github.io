---
layout: default
title: 4.2 Sprint 2 — Realization
parent: 4. Implementation
nav_order: 2
---

# Sprint 2 — Realization

Burndown Chart

## Sprint Planning

### Backlog for this Sprint

| 2.1 | Docker Compose Setup | 2 | 3 | Must |
| 2.2 | PostgreSQL Schema Implementation | 2 | 5 | Must |
| 2.3 | Database Abstractions (Triggers, SPs, Functions) | 2 | 13 | Must |
| 2.4 | 3NF Schema Documentation | 2 | 3 | Must |
| 2.5 | Semantic Search Implementation (pgvector) | 2 | 8 | Must |
| 2.6 | Python Service | 2 | 5 | Must |
| 2.7 | Views | 2 | 3 | Should |
| 2.8 | Simple Search Frontend | 2 | 3 | Should |
| 2.9 | Performance Benchmarking (Vector vs LIKE) | 2 | 5 | Should |
| 2.10 | Sprint 2 Review | 2 | 1 | Must |

---

## Story Outcomes



## 2.1 Docker Compose Setup

## 2.1 Docker Compose Setup

**Goal:** Containerised local development environment with PostgreSQL (pgvector) and Python service running via a single `docker compose up` command.

**What was done:**

The stack was defined in `docker-compose.yml` with two services:

- `postgres` — uses the official `pgvector/pgvector:pg16` image. A healthcheck ensures the Python service only starts once PostgreSQL is accepting connections. Data is persisted via a named volume (`postgres_data`).
- `python-service` — built from a local `Dockerfile` based on `python:3.12-slim`. Serves the search frontend and exposes the semantic search endpoint on port 8000.

The pgvector extension is enabled automatically on first startup via `postgres/init/01_extensions.sql`, which runs through Docker's `docker-entrypoint-initdb.d` mechanism.

**Outcome:** `docker compose up --build` starts both services without errors. PostgreSQL is reachable on port 5432, the Python service on port 8000. Health confirmed via `/health` endpoint returning `{"status": "ok"}`.

**Directory structure:**
```
SEM03/
├── docker-compose.yml
├── postgres/
│   └── init/
│       └── 01_extensions.sql
└── python-service/
    ├── Dockerfile
    ├── requirements.txt
    ├── main.py
    └── frontend/
        └── index.html
```












## Sprint Review

*To be completed at end of Sprint 2.*

**Points committed:** 46 / **Points completed:** —

---

## Retrospective

| What went well | What did not go well | What to change |
|---|---|---|
| | | |
