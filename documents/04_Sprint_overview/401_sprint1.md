---
layout: default
title: 4.1 Sprint 1
parent: 4. Sprint Overview
nav_order: 1
---

# 4.1 Sprint 1

**Period:** 26.10. – 22.11.2026  
**Story points planned:** 37

---

## Sprint Goal

Project planned and evaluated; the SEM03 database runs on a 3-instance CNPG cluster (MVP).

---

## Sprint Backlog

| ID | Story | Points | Priority | Status |
|---|---|---|---|---|
| 1.1 | Repository & GitHub Pages setup, SEM03 archived | 2 | Must | Done |
| 1.2 | Requirements, scope & backlog | 3 | Must | Done |
| 1.3 | Timeline (Gantt) | 2 | Must | Done |
| 1.4 | Risk analysis | 3 | Must | Done |
| 1.5 | Evaluation: Kubernetes distribution, operator, migration tool, object store | 5 | Must | Done |
| 1.6 | System design & architecture | 5 | Must | Open |
| 1.7 | kind cluster with 3 worker nodes | 3 | Must | Done |
| 1.8 | CNPG operator + Cluster manifest (1 primary, 2 replicas, anti-affinity) | 5 | Must | Done |
| 1.9 | Schema import incl. pgvector; `06_tests.sql` passes on the cluster | 5 | Must | Open |
| 1.10 | Self-hosted GitHub Actions runner | 3 | Must | Open |
| 1.11 | Sprint 1 review | 1 | Must | Open |

---

## Story Outcomes

### 1.1 Repository & GitHub Pages Setup

SEM03 repository archived as `SEM03_archived`; new repository and documentation structure set up.

### 1.2 – 1.4 Requirements, Backlog, Timeline, Risks

Results: [3.1 Project Management](../03_Project_overview/301_project_management.md), [3.3 Timeline](../03_Project_overview/303_timeline.md).

### 1.5 Evaluation

Results: [3.2 Evaluation & Architecture](../03_Project_overview/302_architecture_design.md#evaluation). The evaluation confirmed R1, lowered R4 and added R11.

### 1.7 kind Cluster

**Goal:** A local Kubernetes cluster with 1 control plane and 3 worker nodes as the base for G1.

**Setup:** kind and kubectl are installed in WSL2 Ubuntu with [`scripts/install_kind_kubectl.sh`](https://github.com/JJotace/JJotace.github.io/blob/main/scripts/install_kind_kubectl.sh). The cluster is defined in [`k8s/kind/cluster.yaml`](https://github.com/JJotace/JJotace.github.io/blob/main/k8s/kind/cluster.yaml).

```bash
kind create cluster --config k8s/kind/cluster.yaml
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl get nodes
```

```
NAME                  STATUS   ROLES           AGE   VERSION
sem04-control-plane   Ready    control-plane   31s   v1.37.0
sem04-worker          Ready    <none>          14s   v1.37.0
sem04-worker2         Ready    <none>          14s   v1.37.0
sem04-worker3         Ready    <none>          14s   v1.37.0
```

**Findings:**
- Volumes use the `local-path` storage class and stay on the node where they were created (R9).
- The empty cluster uses about 1 GB of memory, so resources are not a problem (R3).

### 1.8 CNPG Cluster

**Goal:** A PostgreSQL cluster with 1 primary and 2 replicas, each on its own worker node.

**Setup:** The CNPG operator is installed from the official release manifest and the cluster is defined in [`k8s/cnpg/cluster.yaml`](https://github.com/JJotace/JJotace.github.io/blob/main/k8s/cnpg/cluster.yaml). It uses PostgreSQL 16 with pgvector and the same database and user as SEM03.

```bash
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.1.yaml
kubectl apply -f k8s/cnpg/cluster.yaml
kubectl wait --for=condition=Ready cluster/pg-shop --timeout=600s
```

The cluster was ready after about 2 minutes. CNPG starts the primary first and then copies it to each replica.

**Pod placement:** Each instance runs on a different node.

```bash
kubectl get pods -l cnpg.io/cluster=pg-shop -L role -o wide
```

```
NAME        READY   STATUS    IP           NODE            ROLE
pg-shop-1   1/1     Running   10.244.4.4   sem04-worker2   primary
pg-shop-2   1/1     Running   10.244.2.5   sem04-worker    replica
pg-shop-3   1/1     Running   10.244.1.4   sem04-worker3   replica
```

**Replication:** Both replicas are connected to the primary and receive changes.

```bash
kubectl exec pg-shop-1 -c postgres -- psql -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
```

```
 application_name | client_addr |   state   | sync_state
------------------+-------------+-----------+------------
 pg-shop-2        | 10.244.2.5  | streaming | async
 pg-shop-3        | 10.244.1.4  | streaming | async
```

**Services:** CNPG creates three services for the cluster.

| Service | Points to | Used for |
|---|---|---|
| `pg-shop-rw` | primary | writes and migrations (G2, G5) |
| `pg-shop-ro` | replicas | search reads (G3) |
| `pg-shop-r` | all instances | not needed |

**Findings:**
- Replication is asynchronous by default. For G2 (no data loss) it has to be synchronous. This is planned for Sprint 2.
- Pod IPs change when a pod is recreated, the service names stay the same. After a failover the application reconnects to `pg-shop-rw` without changes.
- With 3 workers there is no free node for a 4th instance (G3), because the control plane does not run database pods. A test with `instances: 4` confirmed this. The 4th pod stayed `Pending` with the message `0/4 nodes are available: 1 node(s) had untolerated taint(s), 3 node(s) didn't match pod anti-affinity rules`. The kind cluster was therefore recreated with a 4th worker. After that, scaling from 3 to 4 instances took 43 s and back to 3 took 3 s.
- Each instance stores its data on its own node (R9).

---

## Sprint Review

---

## Burndown Chart

---

## Retrospective

### 😊 What went well

### 😟 What did not go well

### 🚀 What to change
