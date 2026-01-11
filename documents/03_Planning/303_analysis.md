---
layout: default
title: 3.3 SWOT Analysis
parent: 3. Planning
nav_order: 3
---

# 3.3 SWOT Analysis

| **Strengths** | **Weaknesses** |
| --- | --- |
| - IaC with Ansible enables fast and reproducible rebuilds<br>- Automation reduces manual errors<br>- Scalable solution via inventory file<br>- Cost efficiency through optimized resource usage (t2.micro/small)<br>- Using widely adopted industry standard tools<br>- Documented so that anyone can follow and reproduce the same results | - Almost from scratch learning of new tools<br>- Single point of failure with monitoring server<br>- Manual AWS infrastructure provisioning required<br>- Basic security features<br>- No alerting when something breaks<br>- Dependency on AWS-specific features |

| **Opportunities** | **Threats** |
| --- | --- |
| - Could be extended with other components such as databases etc.<br>- Integration of alert notifications<br>- AWS part could be automated with Terraform<br>- High availability setup with clustered architecture<br>- Implementation of service discovery | - Limited AWS student budget (50&nbsp;USD)<br>- Security vulnerabilities in public-facing services<br>- IP address changes requiring frequent security group changes<br>- Data loss risk without backups<br>- Technology changes and breaking updates<br>- Time management challenges |
