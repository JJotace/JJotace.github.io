---
layout: default
title: 2.1 Task 
parent: 2. Assignment
nav_order: 1
---

# Task

## Project Title

Server Monitoring Dashboard

## Starting Situation

A homelab environment is being created as a learning environment for Infrastructure as Code (IaC) and monitoring solutions. Currently, within the team, there is a lack of knowledge on automating the deployment and configuration of monitoring tools across multiple servers.

Three Ubuntu servers will be deployed on AWS EC2 for this project:
one dedicated monitoring server and two target servers that will be monitored. The current budget for this activity is 50$, which will limit the time we can have these instances up and running. Throughout the project, these instances will be created and removed as needed in order to preserve said budget, making automation the moreso important.

Manual server monitoring would require logging into each machine individually to check CPU usage, memory, disk space, and network activity, an inefficient and time consuming method.

## Project purpose

The goal of this project is to build an automated monitoring solution. All necessary packages will be installed via Infrastructure as a Code thanks to Ansible. This will make it possible to deploy Prometheus and Grafana repeteadly across all servers with a single command.

The key benefits of this approach are:
- **Automation**: Eliminate manual installation and configuration errors
- **Repeatability**: Recreate the entire infrastructure quickly when servers need to be rebuilt
- **Scalability**: Add new servers to monitoring by just updating an inventory file
- **Real-time visibility**: Monitor all servers from a single dashboard with live metrics
- **Historical tracking**: Store and analyze performance data over time to identify trends

This project serves as a learning experience in basic DevOps skills while solving a problem: monitoring servers efficiently without the need of manual repetitive tasks and checks.


### Project Goals (SMART)

- **Specific**: Deploy a complete monitoring infrastructure consisting of Prometheus and Grafana on one server, with Node Exporter running on two target servers, all configured through Ansible playbooks.

- **Measurable**: 
- All three servers must be fully configured via Ansible with zero manual steps.
- Prometheus must successfully scrape metrics from both target servers.
- Grafana must display at least one functional dashboard showing real-time CPU, memory, disk, and network metrics.
- The complete deployment must be reproducible by running a single playbook command

- **Attractive**: Learn valuable DevOps skills (Ansible, Prometheus, Grafana) while building a project that demostrates Infrastructure as a Code best practices.

- **Realistic**: Uses free-tier/low-cost AWS resources, open-source tools with extensive documentation, and a clear sprint timeline with achievable milestones. The technology stack is widely used in production environments, with plenty of learning resources available.

- **Timed**: The complete project can be completed within 50 hours of work across 3 main Sprints, including a Sprint 0 to help set up the environment before the start.
- Sprint 0: 1 Week
- Sprint 1: 1 Month
- Sprint 2: 1 Month
- Sprint 3: 1 Month


## Steps

The project will be executed in four main phases:

**Sprint 0 - Initial Setup**: Set up the environment installing all necessary software and prepapre working tools and repositories.

**Sprint 1 - Planning & Setup**: Create the project structure, plan and describe epics, user stories and tasks within Jira and create barebone playbooks and documentation structure.

**Sprint 2 - Implementation**: Create Ansible roles for each component (Node Exporter, Prometheus, Grafana), create EC2 instances and templates and deploy these components to the servers. The Node Exporter will expose the metrics from the target servers and Prometheus will collect the data, while Grafana will make it visual via dashboards. Testings to verify that everything works correctly will be executed by the end of the sprint once everything is created and installed.

**Sprint 3 - Documentation & Presentation**: Create comprehensive documentation, enabling this to be recreated and understood by others by reading the documentation. A series of slides will be created with which will then be presented to the SMEs. A project reflection will then be written at the end to review and go through everything created and learnt.


## Assessment criteria

| Criteria | Comments | Points |
|---------------------------------------------------------|------------|--------|
| **1. Substance, structure of content** | | (0 to 5 points) |
| **2. Presentation of theory**<br>(form, language, sources) | | (0 to 5 points) |
| **3. Link between theory and practice**<br>(formal) | | (0 to 5 points) |
| **4. Link between theory and practice**<br>(technical) | | (0 to 5 points) |
| **5. Depth of reflection** | | (0 to 5 points) |
| **Total points** | (points achieved) | (max. 25 points) |

## Grading scale:
Points achieved * 5 / max. points + 1