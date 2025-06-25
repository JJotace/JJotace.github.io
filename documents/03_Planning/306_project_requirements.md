---
layout: default
title: 3.6 Project Requirements
parent: 3. Planning
nav_order: 6
---

# Project Requirements

The project requirements explain in detail the objectives the project needs to meet in order to mark it as completed.

## Functions & Objectives

### Guidelines

- The playbook needs to be the same across all environments in order to be released in production.
- The testing is done in order of environment hierarchy, once the dev. environment is completed, we can move on to the next (te1, te2, prod...)
- No passwords or client identifying data can be shown when running the code.

### Functionality

- The playbook needs to be able to create a working database collector in any of the selected environments.
- Somebody new to this should be able to follow the internal documentation and create a collector without prior experience.

### Non functional objectives

- Increase our database monitoring.
- Reduce the time spent in creating collectors.
- Documentation of the environment and guide.
- Make this tool the standard for onboarding database collectors in our monitoring tool.

### Starting situation

- Ansible controllers for every environment already setup by the company.
- Code deployment tool already setup by the company.
- No current automation for any AppDynamics collectors.
- Monitoring tool setup by the company.
