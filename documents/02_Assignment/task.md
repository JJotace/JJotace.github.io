---
layout: default
title: 2.1 Task
parent: 2. Assignment
nav_order: 1
---

# Task

## Project Title

Smart Database Project

## Starting Situation

As a card collector, I want to build a database solution that simulates a real-world card shop inventory system. The project is based on a fictional Pokémon TCG store that needs to manage cards, inventory, customers, orders, deliveries and payments. No existing database or data model is in place — the full solution is designed and built from scratch as part of this semester project.

## Project Purpose

The purpose of this project is to design and implement a relational database system for a simulated Pokémon TCG card shop, applying the database and software modules covered at TBZ in a personally relevant context. The system manages the full lifecycle of a card shop: inventory, customers, orders, deliveries and payments.

Beyond basic data storage, the database implements automated logic via triggers, transactional business logic via stored procedures, and reusable query abstractions via views. A minimal Python service exposes the database functionality, and pgvector enables semantic card search as the NoSQL component.

## Project Goals (SMART)

**Specific:** Design and implement a PostgreSQL database for a simulated Pokémon TCG card shop, including a normalised schema, database abstractions (triggers, stored procedures, views), pgvector semantic search, and a minimal Python service.

**Measurable:** All stories in the backlog are completed and meet their acceptance criteria. The database will include a defined set of tables, triggers, stored procedures, views, and a working semantic search implementation.

**Attractive:** The project combines relational database theory with modern vector search technology, giving practical experience with tools used in professional environments. The result is a working, documented system that can be reproduced by anyone following the installation guide.

**Realistic:** The full scope is estimated at 99 story points across 4 sprints, calibrated to approximately 50 hours of work at a rate of 2 story points per hour. All technologies are available for free and run locally via Docker Compose.

**Timed:** The project is completed within 50 hours across 3 main sprints, plus a Sprint 0 for environment setup.

| Sprint | Period |
|---|---|
| Sprint 0 — Setup | Apr 24 – May 7 |
| Sprint 1 — Planning | May 8 – May 28 |
| Sprint 2 — Realization | May 29 – Jun 18 |
| Sprint 3 — Documentation | Jun 19 – Jul 8 |

## Sprint Overview

**Sprint 0 — Initial Setup:** Install all required software, set up the GitHub repository and Pages site, configure Jira, and verify the local development environment.

**Sprint 1 — Planning & Design:** Define requirements and scope, create the full backlog with story point estimates, produce the Gantt chart, design the system architecture and tech stack, create the database schema (ERD), and perform the risk analysis.

**Sprint 2 — Realization:** Implement the full Docker Compose stack, PostgreSQL schema, database abstractions (triggers, stored procedures, functions), 3NF documentation, pgvector semantic search, Python service, SQL views, search frontend, and performance benchmarking.

**Sprint 3 — Documentation & Presentation:** Write the installation guide, consolidate all sprint outputs into final documentation, compare actual vs planned timeline, write the project retrospective, and prepare the Kolloquium presentation with live demo.

## Assessment Criteria

| Criteria | Weight | Points |
|---|---|---|
| 1. Substance, structure of content | 1.0 | 0–5 |
| 2. Presentation of theory | 1.0 | 0–5 |
| 3. Link between theory and practice (formal) | 1.0 | 0–5 |
| 4. Link between theory and practice (technical) | 1.0 | 0–5 |
| 5. Depth of reflection | 1.0 | 0–5 |
| 6. Colloquium (product demonstration) | 1.0 | 0–5 |
| **Total** | | **max. 30** |

Grading formula: `points achieved × 5 / max. points + 1`
