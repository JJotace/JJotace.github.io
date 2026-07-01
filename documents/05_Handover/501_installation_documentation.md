---
layout: default
title: 5.1 Installation & Deployment Documentation
parent: 5. Handover
nav_order: 1
---

## 5.1 Installation & Deployment Documentation

**Points:** 3 | **Status:** Complete

### Goal

Provide a complete setup guide so that anyone with the repository can reproduce the full stack from scratch.

---

### Prerequisites

| Requirement | Notes |
|---|---|
| Docker Desktop | Required to run the containers. Any recent version works. On Windows, WSL 2 backend must be enabled. |
| Git | To clone the repository |
| Python 3.12 | Only needed if running `import_cards.py` or `sync_prices.py` outside of Docker |

The Python service itself runs inside Docker — Python does not need to be installed on the host to run the stack.

---

### Setup

**1. Clone the repository**

```bash
git clone https://github.com/JJotace/JJotace.github.io
cd JJotace.github.io
```

**2. Start the stack**

```bash
docker compose up
```

This starts two containers: `smart_db_postgres` (PostgreSQL 16 with pgvector) and `smart_db_service` (Python HTTP service). PostgreSQL initialises automatically on first start — all SQL files in `postgres/init` are executed in order, creating the schema, extensions, triggers, stored procedures, and views.

The Python service waits for PostgreSQL to pass its healthcheck before starting. Once both containers are running, the search frontend is available at `http://localhost:8000`.

**3. Import card data**

The card data is not seeded automatically. Run the import script from the host:

```bash
pip install psycopg2-binary sentence-transformers
python import_cards.py
```

This loads `sets.csv` and `cards.csv` into the database and generates vector embeddings for each card.

**4. (Optional) Sync real prices and images**

```bash
python sync_prices.py
```

Fetches current TCGPlayer market prices and card images via the TCG Price Lookup API. Limited to 200 requests per day on the free tier. Supports `--dry-run` and `--rarity` flags.

---

### Verify the setup

Open `http://localhost:8000` in a browser — the search frontend should load and return results for any card name query.

To connect via DBeaver or another client: host `localhost`, port `5432`, database `smart_db`, user `smart_user`, password `smart_pass`.

---

### Known issues

| Issue | Notes |
|---|---|
| Windows — DBeaver host address | The container IP shown in the terminal (`172.17.x.x`) is WSL-internal. Use `localhost` when connecting from outside Docker. |
| `import_cards.py` on first run | sentence-transformers downloads the embedding model (~90 MB) on first run. This is expected and only happens once. |
| API rate limit | `sync_prices.py` hits the 200 req/day limit before covering all 242 cards. Run across multiple days targeting different rarities with `--rarity`. |
