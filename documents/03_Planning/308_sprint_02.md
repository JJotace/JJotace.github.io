---
layout: default
title: 3.8 Sprint 02
parent: 3. Planning
nav_order: 8
---

# Sprint 2 Review & Retrospective

**Date**: 01.01.2025  
**Location**: Microsoft Teams

**Participants**:
* Student: Juan Cardoso
* PRJ SME: Corrado Parisi
* IAC SME: Armin Dörzbach

---

### Progress Overview

* Documentation: 60%
* Implementation: 90%
* Presentation: 0%

---

### Timeline

![Sprint_2_Timeline_Finished](../../resources/images/Sprint2_end.png)

---

### Status of the project

* **Node Exporter**:Created and successfully deployed, exposing metrics  on port 9100.
* **Prometheus Deployment**: Monitoring server configured with Prometheus.
* **Grafana Deployment**: Grafana service running on port 3000 with basic configuration template deployed.
* **Documentation**: Implementation steps with code examples documented.
* **Questions for Experts**: None during this sprint.

---

### Comparison to Project Goals

* **Project Goals**: On track. Monitoring infrastructure is operational. Still behind in documentation.
* **Sprint 2 Objectives**: All stories completed successfully.
  - SMD-35: Node Exporter
  - SMD-36: Prometheus
  - SMD-37: Grafana & Dashboards
  - SMD-38: Testing & Troubleshooting
  - SMD-42: AWS Provisioning & Configuration

---

### To do

* **Documentation**: Finish project documentation.
* **Testing**: Test everything again before delivering the finished product.
* **Presentation**: Create Powerpoint slides and present the project to the stakeholders.

---

### Issues Encountered

* **OS Confusion**: EC2 templates initially created with Amazon Linux (ec2-user) instead of Ubuntu (ubuntu user), causing SSH connectivity failures. Fixed by recreating templates with correct Ubuntu AMI.

* **Private vs Public IP Problem**: Initial Prometheus configuration used public IPs which could not reach Node Exporters. Solved by adding `private_ip` variable to inventory and updating prometheus.yml.j2 template to use private IPs for scraping.

### Backlog

![Sprint_2_Backlog](../../resources/images/Sprint2_finished_Backlog.png)

## Sprint Retrospective

![Sprint_2_Retrospective](../../resources/images/Sprint2_retrospective.png)



