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
| 1.8 | CNPG operator + Cluster manifest (1 primary, 2 replicas, anti-affinity) | 5 | Must | Open |
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

**Goal:** a local Kubernetes cluster with 3 worker nodes as the base for G1.

**Setup:** kind and kubectl are installed in WSL2 Ubuntu with [`scripts/install_kind_kubectl.sh`](https://github.com/JJotace/JJotace.github.io/blob/main/scripts/install_kind_kubectl.sh), which verifies the download checksums. The cluster is defined in [`k8s/kind/cluster.yaml`](https://github.com/JJotace/JJotace.github.io/blob/main/k8s/kind/cluster.yaml): 1 control plane and 3 workers, Kubernetes version pinned.

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
- The default storage class is `rancher.io/local-path`: volumes stay on the node where they were created. This is the behaviour described in R9 and is tested in the node drain test (G2).
- The empty cluster uses about 1 GB of memory (`docker stats`), which supports the lowered rating of R3.

---

## Sprint Review

---

## Burndown Chart

---

## Retrospective

### 😊 What went well

### 😟 What did not go well

### 🚀 What to change
