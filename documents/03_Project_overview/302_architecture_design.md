---
layout: default
title: 3.2 Evaluation & Architecture
parent: 3. Project Overview
nav_order: 2
---

# 3.2 Evaluation & Architecture

## Evaluation

Story 1.5. Each component is compared against criteria derived from the goals.

### Local Kubernetes Distribution

| Criterion | kind | minikube | k3d |
|---|---|---|---|
| Several worker nodes on one laptop | Yes, each node is a Docker container | Yes (`--nodes`) | Yes, each node is a Docker container |
| Kubernetes flavour | Upstream Kubernetes | Upstream Kubernetes | k3s (reduced distribution) |
| Node drain for G2 | Yes | Yes | Yes |

**Decision: kind.** It runs standard Kubernetes, so test results are not influenced by a reduced distribution like k3s. Its nodes are lightweight Docker containers.

### PostgreSQL Operator

| Criterion | CloudNativePG | Zalando Postgres Operator | Crunchy PGO |
|---|---|---|---|
| Failover | Operator itself, via the Kubernetes API | Patroni inside the pods | Patroni inside the pods |
| `-rw` / `-ro` services | Built in | Master / replica services | Primary / replica services |
| Backup to object store | Barman Cloud Plugin | WAL-G / WAL-E | pgBackRest |
| pgvector | Included in the `standard` image | Not verified | Not verified |
| Licence | Apache 2.0 | MIT | Apache 2.0 code; images under Crunchy Developer Program terms |

**Decision: CloudNativePG.** The operator handles failover itself through Kubernetes, without an extra tool like Patroni, so every step can be followed with `kubectl`. Its standard image already includes pgvector. Because pgvector needs superuser rights to install, CNPG creates the extension instead of a migration (R1).

### Schema Migration Tool

| Criterion | Flyway | Liquibase | Sqitch |
|---|---|---|---|
| Plain SQL migrations (reuse SEM03 scripts) | Yes, versioned `V<n>__name.sql` files | Possible ("formatted SQL"), XML/YAML is the default | Yes |
| Rollback | Undo only in paid editions | Rollback available | Revert scripts per change |
| Licence | Apache 2.0 (open source edition) | Functional Source License (not open source) | MIT |

**Decision: Flyway.** The SEM03 SQL scripts can be reused as versioned migration files almost unchanged. The free edition has no undo, which is acceptable because mistakes are fixed with a new migration.

### Object Store

| Criterion | MinIO | RustFS | Garage | SeaweedFS |
|---|---|---|---|---|
| Maintained | No | Yes | Yes | Yes |
| Documented for the Barman Cloud Plugin | No | Yes, with example configuration | No | No |
| Licence | AGPLv3 | Apache 2.0 | AGPLv3 | Apache 2.0 |

**Decision: RustFS, with Garage as fallback.** MinIO is no longer maintained. RustFS is the only alternative documented for the CNPG backup plugin; since it is still young, Garage is kept as a fallback.

### CI Runner

GitHub-hosted runners cannot reach the local cluster (R2).

| Criterion | Self-hosted runner on the laptop | Actions Runner Controller (runner pods in the cluster) | Manual migration Job |
|---|---|---|---|
| Reaches the cluster | Yes, via kubeconfig | Yes, from inside | Yes |
| Automated after merge | Yes | Yes | No |
| Setup effort | Low | Higher (controller, scale sets) | None |

**Decision: self-hosted runner on the laptop.** It reaches the cluster with the least setup effort. Because the repository is public, it only runs after a merge to `main`, never on pull requests from others (R11).

### Summary

| Component | Choice | Reason |
|---|---|---|
| Local Kubernetes | kind | Upstream Kubernetes, nodes as lightweight containers |
| PostgreSQL operator | CloudNativePG | Failover through the Kubernetes API, pgvector included, Apache 2.0 |
| Schema migrations | Flyway | SEM03 scripts reusable as versioned SQL files |
| Object store | RustFS (fallback: Garage) | Only candidate documented for the Barman Cloud Plugin; MinIO no longer maintained |
| CI runner | Self-hosted runner, pushes to `main` only | Reaches the local cluster; public repository stays protected |

---

## System Design

Story 1.6. *Open.*

---

## Database Schema

The schema is taken over from Semester 3 (9 tables, triggers, stored procedures, views, pgvector embeddings). Design and normalisation are documented in the [SEM03 repository](https://github.com/JJotace/SEM03_archived). In this project the schema moves from init scripts to versioned Flyway migrations (Story 2.5).

---

## Sources

- [kind releases](https://github.com/kubernetes-sigs/kind/releases)
- [CloudNativePG releases](https://github.com/cloudnative-pg/cloudnative-pg/releases)
- [CloudNativePG container images](https://github.com/cloudnative-pg/postgres-containers)
- [CloudNativePG Image Volume Extensions](https://cloudnative-pg.io/docs/1.30/imagevolume_extensions)
- [Barman Cloud Plugin installation](https://cloudnative-pg.io/plugin-barman-cloud/docs/installation/) and [object stores](https://cloudnative-pg.io/plugin-barman-cloud/docs/object_stores/)
- [Zalando Postgres Operator releases](https://github.com/zalando/postgres-operator/releases)
- [Crunchy Postgres Operator](https://github.com/CrunchyData/postgres-operator)
- [Flyway repository](https://github.com/flyway/flyway) and [Flyway Community undo support](https://forum.red-gate.com/discussion/89862/does-flyway-community-edition-supports-undo)
- [Liquibase Community moves to FSL](https://www.liquibase.com/blog/liquibase-community-for-the-future-fsl)
- [MinIO community edition archived](https://vegardit.com/en/blog/minio-alternatives/)
- [RustFS releases](https://github.com/rustfs/rustfs/releases)
