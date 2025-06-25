---
layout: default
title: 2.1 Task 
parent: 2. Assignment
nav_order: 1
---

# Task

## Project Title

DB Collectors automation

## Starting Situation

Within our team in my company, we are in charge of several databases. These databases are monitored through AppDynamics, a full-stack application performance monitoring and analytics platform that helps organizations track, optimize, and troubleshoot application and infrastructure performance in real time.

Setting up one of these databases is currently a repetitive manual process that needs to be done for every single collector we want to create within the monitoring tool.

## Project purpose

This project will be centered around the automation of the process of database collector creation. This will be achieved through ansible playbooks. The goal is that the playbook should be able to fully setup the collector with a few pieces of information added as extra vars in the deployment, such as database name and identifier, which are needed for the jbdc string AppDynamics uses to communicate with the database.

This will decrease the manual labor involved in improving our visibility for our oracle databases, pushing us to easily onboard all of them and offer the end user a better experience by noticing issues before they happen, or allow us to react faster to them.

### Project Goals (SMART)

- **Specific**: Automate the creation of Oracle database collectors in AppDynamics using Ansible.
- **Measurable**: Reduce manual configuration time by at least 90%.
- **Attractive**: Improve the end-user experience through better support made possible thanks to having more visibility and faster database onboarding.
- **Realistic**: Using existing company infrastructure and tools such as REX and AppDynamics.
- **Timed**: Complete and deploy the automation within the project duration.

## Steps

1. **Analyze and plan**
   - Indentify all the databases assigned to our team that haven't yet been onboarded.
   - Define exactly what the code should do and how.
   - Plan according to our current company architecture (dev, test, preprod, prod...)

2. **Ansible Playbook**
   - Design and implement an Ansible playbook that can configure oracle database collectors in AppDynamics.
   - The playbook will be able to tell in which environment we are and use the correct template accordingly.
   - Extra vars will be used in case of needing special values such as ports other than the default.

3. **Documentation**
   - Detailed technical documentation.
   - Description of the architecture, technologies and steps.
   - Screenshots and diagrams to help understand the processes.

4. **Testing and Deployment**
   - Playbook validation through REX testing in all environments.
   - Documenting of test results.
   - Problem solving of possible issues found during the testing phase.

## Deliverable Results
   - Automated database collector playbook written in ansible and deployed through REX.
   - Techincal documentation.

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