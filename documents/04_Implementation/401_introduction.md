---
layout: default
title: 4.1 Introduction
parent: 4. Implementation
nav_order: 1
---

# 4.1 Introduction

An ansible playbook is a YAML based blueprint that automates tasks by executing actions across different hosts, everything defined in the code. It is sort of like executing a list of commands without actually having to do it by hand. Before writing such a playbook, it is important to have a predefined structure, and have it planned right. 

The goal is to end up with a tool not only used for the project but also for the organization, that is capable of improving the monitoring of databases by creating data collectors in AppDynamics by simply executing the playbook. This playbook should be able to be executed by anybody that counts with the respective right, without any prior ansible knowledge. A internal guide has also been created to help the user achieve this.

Here is a brief overview of the topics that the implementation phase of the project will contain:

- **Structure**: The playbook is hosted in an ansible controller with structured directories.
- **Playbook**: An overview of the ansible playbook in charge of creating DB collectors.
- **Monitoring**: AppDynamics, the tool where the DB Collectors are created in.
- **Problems**: Problems encountered during implementation and how they were solved.
