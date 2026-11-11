---
layout: default
title: 3.3 Timeline
parent: 3. Project Overview
nav_order: 3
---

# 3.3 Timeline

## Gantt Chart (Planned)

```mermaid
gantt
    title HA PostgreSQL on Kubernetes (26.10.2026 - 27.01.2027)
    dateFormat  YYYY-MM-DD
    tickInterval 1week

    section Sprint 1
    1.1 Repository & Pages             :done, a1, 2026-10-26, 3d
    1.2 Requirements & backlog         :done, a2, 2026-11-11, 1d
    1.3 Timeline                       :done, a3, 2026-11-11, 1d
    1.4 Risk analysis                  :done, a4, 2026-11-11, 1d
    1.5 Evaluation                     :done, a5, 2026-11-11, 2d
    1.7 kind cluster                   :done, a7, 2026-11-11, 2d
    1.8 CNPG cluster                   :a8, after a7, 2d
    1.9 Schema import & tests          :a9, after a8, 2d
    1.6 System design                  :a6, 2026-11-14, 2d
    Feedback session 1                 :milestone, 2026-11-16, 0d
    1.10 Self-hosted runner            :a10, 2026-11-17, 4d
    1.11 Sprint 1 review               :milestone, 2026-11-22, 0d

    section Sprint 2
    2.1 Planning & risk review         :b0, 2026-11-23, 1d
    2.2 Failover test plan             :b1, after b0, 2d
    2.4 Python service on Kubernetes   :b3, after b0, 4d
    2.3 Failover tests                 :b2, after b3, 6d
    2.5 Flyway migrations              :b4, after b1, 4d
    2.6 PR pipeline                    :b5, after b4, 6d
    2.7 Deploy pipeline                :b6, after b5, 5d
    2.8 Theory                         :b7, after b2, 4d
    Feedback session 2                 :milestone, 2026-12-14, 0d
    2.9 Sprint 2 review                :milestone, 2026-12-20, 0d

    section Sprint 3
    3.1 Planning & risk review         :c0, 2026-12-21, 1d
    3.2 Scaling & -ro                  :c1, after c0, 4d
    3.3 Backups                        :c2, after c1, 4d
    3.4 PITR                           :c3, after c2, 4d
    3.5 Installation docs              :c4, after c3, 3d
    3.6 Final reflection               :c5, after c4, 3d
    3.7 Sprint 3 review                :milestone, 2027-01-17, 0d

    section Closure
    Feedback session 3                 :milestone, 2027-01-22, 0d
    C.1 Incorporate feedback           :d1, 2027-01-22, 3d
    C.2 Presentation & demo            :d2, 2027-01-18, 9d
    Submission & presentation          :milestone, 2027-01-27, 0d
```

## Story Points per Sprint

| Phase | Planned | Actual |
|---|---|---|
| Sprint 1 | 37 | |
| Sprint 2 | 39 | |
| Sprint 3 | 24 | |
| Closure | 5 | |
| **Total** | **105** | |

Sprint 3 is planned lighter because it includes the Christmas holidays (R8).
