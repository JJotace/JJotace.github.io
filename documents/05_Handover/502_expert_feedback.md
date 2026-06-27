---
layout: default
title: 5.2 Einzelbesprechungen
parent: 5. Handover
nav_order: 2
---

# Expert Feedback

## Overview

| Date | Time | Location | Topic | Participants | Status |
|---|---|---|---|---|---|
| 26.05.26 | 20:00 | MS Teams | [Einzelbesprechung 1](#einzelbesprechung-1) | Juan Cardoso, Florian Huber | Done |
| 15.06.26 | 19:30 | MS Teams | [Einzelbesprechung 2](#einzelbesprechung-2) | Juan Cardoso, Florian Huber | Done |
| 18.06.26 | 17:00 | MS Teams | [Einzelbesprechung 3](#einzelbesprechung-3) | Juan Cardoso, Yves Nussle | Done |

---

## Einzelbesprechung 1

**Topic:** Sprint 1 — Project Management Review

**Discussion:**
- Sprint 1 planning and deliverables reviewed
- Absence during sprint period discussed and confirmed as acceptable
- Documentation structure and sprint file content discussed

**Feedback:**
- Document not just what is prioritised but why — reasoning behind the order must be visible
- Explain how story points were estimated, not just the values
- Sprint review must clearly state what was achieved and the total story points completed per sprint
- Testing should not be left entirely to Sprint 3 — deliver and test incrementally
- Expert has no Jira access — all sprint content must be visible directly in GitHub Pages

**Improvements:**
- Add prioritisation reasoning to backlog documentation
- Add estimation methodology explanation to project management section
- Sprint review sections now include story points achieved
- Incremental testing approach to be reflected in Sprint 2 planning
- Sprint files document all stories and tasks directly so the expert can follow without Jira access


## Einzelbesprechung 2

**Topic:** Sprint 2 — Realization & Project Structure Review

**Discussion:**
- Sprint structure reviewed: currently one sprint per concern rather than parallel realization sprints
- Story point estimation discussed — single 13-point story flagged as too large
- Abgrenzung section discussed; scope exclusions not clearly defined
- Retrospective depth reviewed
- Demo format discussed

**Feedback:**
- Use 3 realization sprints instead of one dedicated per concern — each sprint should re-plan based on what was learned, reducing risk incrementally (agile principle)
- A single 13-point story for triggers and stored procedures is too large; split it into smaller stories
- Add an Abgrenzung section: a short title and description of what is explicitly out of scope (Won't Have items)
- Retrospectives need more depth
- Consider recording a video for the demo

**Improvements:**
- Replan realization sprints to follow agile incremental approach with re-planning each iteration next project
- Split the triggers/stored procedures story into smaller, independent stories
- Add Abgrenzung section to project management documentation
- Expand retrospective sections in sprint files
- Evaluate video recording as demo format


## Einzelbesprechung 3

**Topic:** Sprint 2 — Database Implementation Status

**Discussion:**
- Live demo attempted via DBeaver; lacked experience with the tool
- Design decisions questioned
- Role of pgvector and what it concretely adds to the system questioned
- Demo coverage of triggers and stored procedures discussed
- Scope of the frontend relative to the database discussed

**Feedback:**
- Demo must cover every trigger and stored procedure with a prepared test case — explain what each does and why it was implemented that way in the code
- Be able to justify implementation decisions: for each mechanism, explain what alternatives existed and why the chosen approach was used
- Understand pgvector at a functional level — what problem it solves, how similarity search works, what the vector column actually contains
- The HTML frontend is not the focus — the database is the deliverable
- Core expectation: deep understanding of the database internals, not just that they work

**Improvements:**
- Prepare a structured demo script covering every trigger and SP with test inputs and expected outputs
- Study and be able to explain code decisions and function