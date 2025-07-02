---
layout: default
title: 3.5 Risk Management
parent: 3. Planning
nav_order: 5
---

# 3.5 Risk Management

For the risk management matrix, intially, Jira tool was the go-to idea, since it is one of the project's components, but a bug within the tool made this impossible.
Hence why a more modest markdown overview was used to display the below factors that could potentially affect the project's timely success.

Within my company, the structure for the database agent path will soon be changing with the implementation of on-prem dedicated servers. This is a major risk for my project, as highlighted in the risk matrix below. There is no definite day for this change, which no doubt would delay the implementation of the project by adding new rules or things that take play in the execution of the playbook and structure of the code.

| **Risk**                      | **Likelihood** | **Severity**           | **Risk Rating** | **Category**   |
|-------------------------------|:--------------:|:----------------------:|:---------------:|:--------------:|
| Company policies              | 2 (Slight)     | 2 (Significant Impact) | 4               | Low            |
| Bugs and errors               | 3 (Feasible)   | 3 (Serious Impact)     | 9               | Medium         |
| Lack of time                  | 4 (Likely)     | 3 (Serious Impact)     | 12              | Medium         |
| Lack of Ansible knowledge     | 4 (Likely)     | 4 (Major Impact)       | 16              | High           |
| Internal structure changes    | 5 (Very Likely)| 4 (Major Impact)       | 20              | High           |

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