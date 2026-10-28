---
layout: default
title: 1. Introduction
nav_order: 1
permalink: /
---

# Introduction

This project moves the Pokémon TCG shop database from Semester 3 off a single Docker container and onto a Kubernetes cluster. CloudNativePG runs PostgreSQL as one primary and two replicas with automatic failover. Schema changes are versioned with Flyway and applied by a CI/CD pipeline instead of by hand.

All planning, backlog, sprint progress and decisions are documented on this site. No separate project management tool is used, so every reader sees the full project state without an extra login.

---

## Documentation structure

| Section | Contents |
|---|---|
| [2. Assignment](./documents/02_Assignment/) | Starting point, goals, scope, assessment criteria |
| [3. Project Overview](./documents/03_Project_overview/) | Project management, evaluation and architecture, timeline |
| [4. Sprint Overview](./documents/04_Sprint_overview/) | Sprints 1–3 and closure: stories, outcomes, reviews, retrospectives; one-page summary per sprint |
| [5. Handover](./documents/05_Handover/) | Installation, expert meetings, glossary, final reflection |

---

# Disclaimer

For development and documentation purposes, AI assistance was used as a supporting tool to troubleshoot errors, explain unfamiliar concepts, and improve the quality of written text.
