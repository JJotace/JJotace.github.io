---
layout: default
title: 4.2 Project Structure
parent: 4. Implementation
nav_order: 2
---

# 4.2 Project Structure



## Visual Structure plan

![Server Monitoring Structure](../../resources/images/Monitoring_Structure.png)


## Directory Structure

The directory structure should look as follows:

monitoring-project/
├── ansible.cfg
├── inventory.ini
├── playbook.yml
├── README.md
├── group_vars/
├── host_vars/
└── roles/
    ├── node-exporter/
    │   ├── tasks/
    │   ├── templates/
    │   ├── handlers/
    │   └── files/
    ├── prometheus/
    │   ├── tasks/
    │   ├── templates/
    │   ├── handlers/
    │   └── files/
    └── grafana/
        ├── tasks/
        ├── templates/
        ├── handlers/
        └── files/

**Creating project structure**
sudo mkdir SEM02
chown frost:frost SEM02
mkdir -p roles/{node-exporter,prometheus,grafana}/{tasks,templates,handlers,files}
mkdir group_vars host_vars
touch ansible.cfg
touch inventory.yml
touch main.yml
touch README.md

frost@Hitman:~/SEM02$ ls -ltrh
total 24K
drwxr-xr-x 5 frost frost 4.0K Nov 12 10:46 roles
drwxr-xr-x 2 frost frost 4.0K Nov 12 10:46 host_vars
drwxr-xr-x 2 frost frost 4.0K Nov 12 10:46 group_vars
-rw-r--r-- 1 frost frost    0 Nov 12 10:48 main.yml
-rw-r--r-- 1 frost frost    0 Nov 12 10:49 README.md
-rw-r--r-- 1 frost frost  508 Nov 12 10:58 inventory.yml
-rw-r--r-- 1 frost frost  335 Nov 12 11:09 ansible.cfg