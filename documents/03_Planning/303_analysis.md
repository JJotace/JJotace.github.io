---
layout: default
title: 3.3 SWOT Analysis
parent: 3. Planning
nav_order: 3
---

# 3.3 SWOT Analysis

A SWOT analysis helps identify the influencing factors of a project: what is working well (strengths), what could cause problems (weaknesses), where there are chances to improve or grow (opportunities), and what might go wrong (threats). It is a good way to get a clear picture of the project's situation.

| Strengths                                                                     | Weaknesses                                                                    |
|-------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| IaC with Ansible enables fast and reproducible rebuilds                      | Almost from scratch learning of new tools                                     |
| Automation reduces manual errors                                             | Single point of failure with monitoring server                                |
| Scalable solution via inventory file                                         | Manual AWS infrastructure provisioning required                               |
| Cost efficiency through optimized resource usage (t2.micro/small)            | Basic security features                                                       |
| Using widely adopted industry standard tools                                 | No alerting when something breaks                                             |
| Documented so that anyone can follow and reproduce the same results          | Dependency on AWS-specific features                                           |


| Opportunities                                                                 | Threats                                                                       |
|-------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| Could be extended with other components such as databases etc.               | Limited AWS student budget (50 USD)                                           |
| Integration of alert notifications                                           | Security vulnerabilities in public-facing services                            |
| AWS part could be automated with Terraform                                   | IP address changes requiring frequent security group changes                  |
| High availability setup with clustered architecture                          | Data loss risk without backups                                                |
| Implementation of service discovery                                          | Technology changes and breaking updates                                      
