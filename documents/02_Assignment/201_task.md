---
layout: default
title: 2.1 Task
parent: 2. Assignment
nav_order: 1
---

# Task

## Project Title

Highly Available PostgreSQL Database on Kubernetes with CloudNativePG and Automated Schema Migrations via a CI/CD Pipeline

**Modules:** Project Management (Florian Huber), DevOps, CNC – Cloud-native Core (Philip Stark)

---

## Starting Situation

Semester 3 produced a PostgreSQL 16 + pgvector database for a simulated Pokémon TCG shop: 9 tables, triggers, stored procedures, views, and a minimal Python service with semantic search ([SEM03 repository](https://github.com/JJotace/SEM03_archived)). The database runs as a single container via Docker Compose. The schema is created by the init scripts `01_extensions.sql` to `08_add_image_url.sql`; later changes were applied by hand.

| Gap | Consequence |
|---|---|
| One database container, no replication | Container or host lost = shop offline |
| No backups | Lost data cannot be recovered |
| Schema changes not versioned or automated | No way to verify that the running database matches the repository |

---

## Project Goals

| ID | Goal | Measured by | Priority |
|---|---|---|---|
| G1 | **DB cluster:** kind cluster with 3 worker nodes. CNPG cluster with 1 primary + 2 replicas (streaming replication), spread across nodes via pod anti-affinity. Existing schema incl. pgvector, triggers, procedures and views imported. | All tests in `06_tests.sql` pass against the cluster. | Must |
| G2 | **Failover:** deleting the primary pod and draining its node triggers automatic promotion. The Python service reconnects via the `-rw` service without config changes. | Test protocol with measured downtime (target < 60 s) and no loss of confirmed transactions (synchronous replication). | Must |
| G3 | **Scaling:** instances changed declaratively 3 → 4 → 3; CNPG builds the new replica automatically. Semantic search reads via `-ro`, stored procedures write via `-rw`. | Test protocol of both scaling steps and the read/write split. | Should |
| G4 | **Backup/restore:** WAL archiving and daily base backups via the Barman Cloud Plugin to an S3-compatible object store. | One point-in-time recovery into a new cluster; data compared with the original. | Should |
| G5 | **CI/CD for schema changes:** SQL scripts converted to versioned Flyway migrations. Every pull request runs the migrations and tests against a temporary PostgreSQL + pgvector instance. After merge, a Kubernetes Job runs the migration against `-rw` before the Python service is rolled out. | A deliberately broken commit stops the pipeline without touching the running database. | Must |

The < 60 s downtime target is an estimate; it is verified by measurement in Sprint 2. Rollback of a schema change is a forward fix (new migration), because Flyway Community has no undo.

---

## Out of Scope

- Write scaling and sharding ("scalable" means read replicas only)
- Multi-cluster and multi-region setups
- Automatic schema rollback

---

## Sprint Overview

| Phase | Period | Focus | Feedback |
|---|---|---|---|
| Sprint 1 | 26.10. – 22.11.26 | Backlog, evaluation, system design; kind cluster, CNPG, schema import, self-hosted runner (G1) | Feedback session 1 (~16.11.) |
| Sprint 2 | 23.11. – 20.12.26 | Failover tests, Python service on Kubernetes, Flyway, pipeline (G2, G5) | Feedback session 2 (~14.12.) |
| Sprint 3 | 21.12.26 – 17.01.27 | Scaling, backup and PITR (G3, G4), reflection, presentation | — |
| Closure | 18. – 27.01.27 | Incorporate feedback, submission, final presentation | Feedback session 3 (~22.01.) |

---

## Assessment Criteria

| Criterion | Weight |
|---|---|
| 1. Substance, structure of content | 0.2 |
| 2. Presentation of theory | 0.2 |
| 3. Link between theory and practice (formal) | 0.2 |
| 4. Link between theory and practice (technical) | 2.0 |
| 5. Depth of reflection | 1.0 |
| 6. Colloquium | 1.0 |
