---
layout: default
title: 3.4 Architecture Design
parent: 3. Planning
nav_order: 4
---

# 3.4 Architecture Design

## Tech Stack Decision
 
For each major component, two options were compared before making a decision.
 
### Relational Database: PostgreSQL vs MySQL
 
| Criteria | PostgreSQL | MySQL |
|---|---|---|
| Stored procedures | PL/pgSQL with transaction control and error handling | Supported, but less flexible |
| Vector search | pgvector extension available | No built-in vector extension |
| Extensibility | Custom types, extensions, jsonb | More limited extension ecosystem |
| Docker support | Official image available | Official image available |
 
**Decision: PostgreSQL.** This project needs stored procedures, triggers, and pgvector for semantic search. PostgreSQL supports all three natively. MySQL has no built-in vector search extension and would require an external tool to cover that requirement.
 
### Vector Search: pgvector vs Elasticsearch
 
| Criteria | pgvector | Elasticsearch |
|---|---|---|
| Setup | One command: `CREATE EXTENSION vector;` | Separate service with its own container and configuration |
| Integration | Runs inside PostgreSQL, queries with standard SQL | Separate REST API |
| Resource usage | Minimal — uses existing DB | Needs 1–2 GB of memory on its own |
| Dataset fit | Good for small to medium datasets | Built for very large-scale search |
 
**Decision: pgvector.** The cards dataset is small. pgvector runs inside PostgreSQL as an extension, so there is no extra service to manage. Elasticsearch would be overkill for this scale.
 
### Application Layer: Minimal Python Service vs Full REST Framework
 
| Criteria | Minimal Python service | FastAPI / Flask |
|---|---|---|
| Scope fit | Enough for calling stored procedures and exposing search | Full framework with routing, validation, auto-generated docs |
| Setup | Only needs psycopg2 | Additional dependencies and project structure |
| Development time | Low — focused on DB interaction | Higher — time spent on API design |
 
**Decision: Minimal Python service.** Based on feedback from the subject expert, the application layer was scoped down. The graded deliverable is the database, not the API. The Python service only needs to call stored procedures and expose the semantic search endpoint. A full framework like FastAPI would shift time and focus away from the database work.
 
### Containerization: Docker Compose vs Manual Setup
 
Docker Compose was chosen without a formal comparison because the alternatives do not fit the project context. Running PostgreSQL and Python directly on the host would work, but the setup differs per operating system and is harder to document reproducibly. With Docker Compose, the full stack starts with docker compose up — the environment is consistent, and the docker-compose.yml file itself serves as documentation of the infrastructure.

### Frontend: Static HTML/JS vs React SPA
 
| Criteria | Static HTML/JS (served by Python service) | React SPA |
|---|---|---|
| Complexity | A single HTML file with fetch calls | Full framework with build tooling |
| Hosting | Served by the Python service inside Docker | Would need its own build and hosting setup |
| Purpose | Simple search UI for the Kolloquium demo | Full application interface |
 
**Decision: Static HTML/JS served by the Python service.** The frontend is not a graded deliverable. It exists only to demonstrate semantic search during the Kolloquium. Serving it from the Python service keeps everything self-contained: `docker compose up` starts the database, the API, and the search UI together.
 
### Summary
 
| Component | Choice | Reason |
|---|---|---|
| Database | PostgreSQL | Supports pgvector, PL/pgSQL, triggers natively |
| Vector search | pgvector | Runs inside PostgreSQL, no extra service |
| Application layer | Minimal Python service | DB is the deliverable, not the API |
| Containerization | Docker Compose | One-command setup for reproducibility |
| Frontend | Static HTML/JS | Simple demo UI, not graded |
| Project management | Jira | Sprint and backlog tracking |
| Documentation | GitHub Pages (Jekyll) | Public, versioned, accessible to experts |
 
---
 
## System Design
 
The application runs entirely inside Docker Compose.
 
### Component Overview
 
```
┌─────────────────────────────────────────┐
│            Docker Compose               │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │     Python Service (port 8000)    │  │
│  │     - Serves search frontend      │  │
│  │     - Calls stored procedures     │  │
│  │     - Generates embeddings        │  │
│  │     - Exposes search endpoint     │  │
│  └──────────────┬────────────────────┘  │
│                 │ psycopg2              │
│                 ▼                       │
│  ┌───────────────────────────────────┐  │
│  │     PostgreSQL + pgvector         │  │
│  │     - Relational schema           │  │
│  │     - Triggers & stored procs     │  │
│  │     - Views                       │  │
│  │     - Vector embeddings           │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Database Schema Design