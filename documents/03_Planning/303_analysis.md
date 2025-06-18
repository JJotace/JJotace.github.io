---
layout: default
title: 3.3 SWOT Analysis
parent: 3. Planning
nav_order: 3
---

# 3.3 SWOT Analysis

A SWOT analysis helps identify the influencing factors of a project: what is working well (strengths), what could cause problems (weaknesses), where there are chances to improve or grow (opportunities), and what might go wrong (threats). It is a good way to get a clear picture of the project's situation.

| Strengths                                                                | Weaknesses                                                                 |
|--------------------------------------------------------------------------|----------------------------------------------------------------------------|
| Automation reduces manual effort and human error                         | Initial setup and scripting require a fairly high technical knowledge      |
| Reusable playbook can be scaled across environments and future databases | Dependency on specific tools (e.g., REX, AppDynamics)                      |
| Increases configuration and implementation speed                         | Time-consuming to help and support everybody struggling with DB onboarding |
| Infrastructure and rights already provided by the company                | Limited to company-provided infrastructure and policies                    |

| Opportunities                                                            | Threats                                                                    |
|--------------------------------------------------------------------------|----------------------------------------------------------------------------|
| Expansion to other database types (e.g., PostgreSQL)                     | Changes in infrastructure or tool versions could break automation          |
| Foment interest in improving and optimizing our health metrics           | Risk of incomplete testing across all unique environments and zones        |
| Other teams can also benefit from my automation                          | Knowledge silos if documentation or training is insufficient               |
| Potential to become a company-wide onboarding standard                   | Security or compliance constraints affecting playbook execution            |

Through this analysis, it is safe to say that this project does have it's fair share of challenges, mainly being so dependant on company infrastructure and policies. Said this, it is also an advantage to already have a functioning monitoring tool in place and an easy way of testing the playbooks, as well as having a reference on how the architecture of such playbook needs to look like. This project has great potential to become the standard for such procedures and will greatly reduce the time we have to spend creating these collectors by hand. Adressing the idenfitied threats and weaknesses will be key to ensuring this project's short and long term success.