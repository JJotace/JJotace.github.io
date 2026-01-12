---
layout: default
title: 3.5 Risk Management
parent: 3. Planning
nav_order: 5
---

# 3.5 Risk Management Matrix

For the risk management matrix, a straightforward markdown approach was chosen to keep things simple and focus on what can keep the project from being completed on time.

The biggest challenge for this project will be the learning curve for the software, as this is the team's first time using Ansible outside of an already established company structure, and the first time using Grafana and Prometheus. Time pressure combined with knowledge gaps could delay the implementation phase.

Another big risk that would halt the project as a whole would be running out of budget on AWS. Everytime something is being tested, new servers need to be deployed, and then removed. Forgetting even once to do this could cost most of the budget for the project if not all, depending on how many days this is left unatended.

| **Risk**                           | **Likelihood** | **Severity**           | **Risk Rating** | **Category**   |
|------------------------------------|:--------------:|:----------------------:|:---------------:|:--------------:|
| AWS credit exhaustion              | 4 (Likely)     | 5 (Catastrophic)       | 20              | High           |
| Lack of Ansible/monitoring knowledge | 5 (Very Likely)| 3 (Serious Impact)     | 15              | Medium         |
| Time underestimation               | 4 (Likely)     | 3 (Serious Impact)     | 12              | Medium         |
| Security misconfigurations         | 3 (Feasible)   | 4 (Major Impact)       | 12              | Medium         |
| SSH connectivity issues            | 3 (Feasible)   | 3 (Serious Impact)     | 9               | Low            |
| Work loss (no version control)     | 2 (Slight)     | 4 (Major Impact)       | 8               | Low            |

**Legend:**
- *Likelihood*:  
  1 = Very unlikely  
  2 = Slight  
  3 = Feasible  
  4 = Likely  
  5 = Very likely  
- *Severity*:  
  1 = Minor  
  2 = Significant  
  3 = Serious  
  4 = Major impact  
  5 = Catastrophic/Fatal  
- *Risk Rating*: Likelihood × Severity  
- *Category*:  
  - Minimal: 1-2  
  - Low: 3-9  
  - Medium: 10-15  
  - High: 16-20  
  - Extreme: 25  

## 3.5.1 Risk Management handling

To manage the project risks, weekly meetings are held to review the current risk matrix and discuss any possible changes or new problems that might have come up. During these meetings, the risk likely-hood is reassesed to see if something within the project needs to be changed, or what the best course of action is in case any of these risks were to actually affect the project. This regular review helps with proactivity and helps adjusting plans quickly to minimize negative effects on the project and stay within the deadline.