---
layout: default
title: 3.6 Project Requirements
parent: 3. Planning
nav_order: 6
---

# Project Requirements

The project requirements explain in detail the objectives the project needs to meet in order to mark it as completed.

# Functions & Objectives

## Guidelines

This project focuses on creating a fully automated server monitoring solution using Infrastructure as a Code (IaC) principles. No manual server configuration or deployment is permitted, everything needs to be done via Ansible playbooks. The project needs to be reproducible, meaning, anyone with the project files can deploy an identical monitoring infrastructure from scratch. This project needs to be fully created within a 50$ AWS student budget. Instances must only run while actively testing.

### Software Stack:
- **Ansible** for automation.
- **Prometheus** for metrics collection and storage
- **Grafana** for data visualization
- **Node Exporter** for exposing system metrics
- **AWS EC2** running Ubuntu

## Functionality
### Core System Functions:

1. **Automated Deployment**
    * Single command execution (ansible playbook trigger) deploys the entire monitoring infrastructure
    * Zero manual configuration on any server
    * Scalable
    * All configurations are made via Ansible templates

2. **Metrics Collection**
    * Node Exporter runs on all servers exposing system metrics on port 9100
    * Metrics include at least: CPU, memory usage, disk space, network traffic and system load
    * Prometheus scrapes metrics from target servers every 15 seconds
    * Data is retained for 24 hours

3. **Data Visualization**
    * Grafana provides a web-based dashboard via http://< monitoring-ip >:3000
    * Dashboard displays comprehensive metrics
    * Real-time updates showing current system state

4. **Service Management**
    * Services automatically start on system boot
    * Ansible handlers restart services when configuration changes
    * Services status can be checked and reports online


## Non functional objectives

1. **Realiability**
    * Ansible tasks can be executed multiple times without causing errors or duplicating configurations
    * Services must survive reboots and automtically restart

2. **Maintainability**
    * Code organized into reusable Ansible roles (DRY principles)
    * Documentation allows for reproduction without prior knowledge

3. **Scalability**
    * Servers can be added via inventory updates for horizontal scalability
    * Vertical scalability possible via EC2 instance size if monitoring server can't handle loads

4. **Performance**
    * Dashboard loads within 3 seconds
    * Metrics update in real time (every 15 seconds)

## Starting situation

- Windows system with WSL2 installed
- Ansible installed in WSL2 environment
- AWS account with student credits (50$)
- SSH key pair stored at ~/.ssh/aws-key.pem
- Understanding of Linux commands and SSH
- Basic understanding of Ansible


