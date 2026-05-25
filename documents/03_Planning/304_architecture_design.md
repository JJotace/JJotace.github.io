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

### Data Flow
 
1. **Card data import**: A CSV file with Pokémon card data is loaded into PostgreSQL via a bulk import script. The Python service generates vector embeddings for each card description and stores them in the `cards.vector` column.
2. **Semantic search**: The user opens `localhost:8000` in a browser and enters a search query. The Python service converts the query into an embedding, runs a nearest-neighbour search against pgvector, and returns the results as JSON.
3. **Business operations**: Purchases, cancellations, and restocking are handled by stored procedures inside PostgreSQL. The Python service calls these procedures but contains no business logic itself.
4. **Automated side effects**: Triggers handle automatic operations like logging price changes to `price_history`, syncing order status when a payment is confirmed, and updating timestamps.


### Docker Compose Structure
 
| Service | Image | Purpose | Port |
|---|---|---|---|
| `db` | `pgvector/pgvector:pg16` | PostgreSQL with pgvector | 5432 |
| `app` | Custom Python image | Frontend, search, stored procedure calls | 8000 |
 
The PostgreSQL container mounts an `init.sql` volume that creates the schema, triggers, stored procedures, and views on first startup. The Python service waits for the database to be ready before starting.

## Database Schema Design

### Entity-Relationship Overview
 
The schema models a card shop with the following relationships:
 
- A **set** contains many **cards** (1:N)
- A **card** appears in many **inventory** entries, one per condition (1:N)
- A **customer** places many **orders** (1:N)
- An **order** contains many **order items** (1:N), each referencing a card
- An **order** has one **delivery** (1:1)
- An **order** has one **payment** (1:1)
- An **inventory** entry can have many **price history** records (1:N)

### Schema Diagram (ERD)
 
*The ERD will be added here once the schema is implemented in Sprint 2, generated from the live database using DBeaver.*
 
### Table Definitions
 
#### sets
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| name | VARCHAR | NOT NULL |
| release_date | DATE | |
 
#### cards
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| name | VARCHAR | NOT NULL |
| rarity | VARCHAR | |
| set_id | INTEGER | FOREIGN KEY → sets(id) |
| vector | vector | pgvector embedding column |
 
**Indexes**: `set_id`, `rarity`
 
#### inventory
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| card_id | INTEGER | FOREIGN KEY → cards(id) |
| condition | VARCHAR | NOT NULL |
| quantity | INTEGER | CHECK (quantity >= 0) |
| price | NUMERIC | CHECK (price > 0) |
| created_at | TIMESTAMP | DEFAULT NOW() |
| updated_at | TIMESTAMP | DEFAULT NOW() |
 
**Indexes**: `card_id`
 
#### price_history
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| inventory_id | INTEGER | FOREIGN KEY → inventory(id) |
| old_price | NUMERIC | NOT NULL |
| new_price | NUMERIC | NOT NULL |
| changed_at | TIMESTAMP | DEFAULT NOW() |
 
#### customers
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| name | VARCHAR | NOT NULL |
| email | VARCHAR | UNIQUE, NOT NULL |
| address | TEXT | |
| shipping_address | TEXT | |
| created_at | TIMESTAMP | DEFAULT NOW() |
| updated_at | TIMESTAMP | DEFAULT NOW() |
 
#### orders
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| customer_id | INTEGER | FOREIGN KEY → customers(id) |
| status | order_status | ENUM: PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED |
| total | NUMERIC | |
| created_at | TIMESTAMP | DEFAULT NOW() |
| updated_at | TIMESTAMP | DEFAULT NOW() |
 
**Indexes**: `customer_id`
 
#### order_items
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| order_id | INTEGER | FOREIGN KEY → orders(id) |
| card_id | INTEGER | FOREIGN KEY → cards(id) |
| quantity | INTEGER | NOT NULL |
| unit_price | NUMERIC | Snapshot of price at time of purchase |
 
**Indexes**: `order_id`
 
#### deliveries
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| order_id | INTEGER | FOREIGN KEY → orders(id) |
| address | TEXT | NOT NULL |
| status | VARCHAR | |
| estimated_date | DATE | |
 
#### payments
 
| Column | Type | Constraints |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| order_id | INTEGER | FOREIGN KEY → orders(id) |
| amount | NUMERIC | NOT NULL |
| method | VARCHAR | |
| status | VARCHAR | |
 
### Normalization (3NF)
 
The schema is designed in Third Normal Form (3NF).
 
**1NF:** All columns contain single values. There are no repeating groups. Each table has a primary key.
 
**2NF:** Every non-key column depends on the full primary key. Since all tables use a single-column key (`id`), partial dependencies are not possible.
 
**3NF:** No non-key column depends on another non-key column. Notable cases:
 
- `orders.total` could be calculated from the order items, but is stored directly for easier querying. The stored procedure that creates orders sets this value, so it stays consistent.
- `customers.shipping_address` is separate from `address` because billing and shipping addresses are independent — one does not determine the other.
- `order_items.unit_price` stores the price at the time of purchase, not a reference to the current inventory price. This way, historical orders stay accurate even if prices change later.

### Design Decisions
 
**ENUM for order status:** The order status uses a PostgreSQL ENUM type with a fixed set of values (`PENDING`, `CONFIRMED`, `SHIPPED`, `DELIVERED`, `CANCELLED`).
 
**Separate `price_history` table:** Price changes are tracked in their own table, populated automatically by a trigger. This makes it easy to query price trends per item.
 
**Surrogate keys (`SERIAL id`):** All tables use auto-incrementing integer primary keys. Card names are not unique across sets (the same Pokémon can appear in multiple sets), and emails can change, so natural keys would not be reliable.

**pgvector column on `cards`:** The vector embedding represents a card's description, which is an attribute of the card itself. It does not change per inventory entry or order, so it belongs on the `cards` table rather than on `inventory` or a separate table.

### External Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| PostgreSQL | 16 | Relational database |
| pgvector | 0.8.2 | Vector similarity search extension |
| Python | 3.12 | Application runtime |
| psycopg2 | 2.9.12 | PostgreSQL driver for Python |
| sentence-transformers | 5.5.1 | Generates vector embeddings for card descriptions |