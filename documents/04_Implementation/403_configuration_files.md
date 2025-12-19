---
layout: default
title: 4.3 Configuration Files
parent: 4. Implementation
nav_order: 3
---

# 4.3 Configuration Files

## Introduction

The configuration files for the main directory /SEM02 are consolidated and described within this section of the documentation.

## Configuration Files

### Ansible-Configuration (`ansible.cfg`) 
```ini
[defaults]
inventory = inventory.yml
host_key_checking = False
retry_files_enabled = False
log_path = ./ansible.log

[privilege_escalation]
become = True
```

### Inventory File (`inventory.yml`)

The IPs must be replaced everytime new instances are created in AWS.

 ```yaml
---
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/aws-key.pem
    ansible_python_interpreter: /usr/bin/python3

  children:
    monitoring:
      hosts:
        monitoring-server:
          ansible_host: <IP>
          private_ip: <IP>

    targets:
      hosts:
        target-server-1:
          ansible_host: <IP>
          private_ip: <IP>
        target-server-2:
          ansible_host: <IP>
          private_ip: <IP>
```

### Main Playbook (`main.yml`)

This is the main playbook, this is what gets executed in order to trigger every task.

```yaml
---
- name: Deploy Node Exporter to target servers
  hosts: targets
  become: true
  roles:
    - node-exporter

- name: Deploy Prometheus to monitoring server
  hosts: monitoring
  become: true
  roles:
    - prometheus

- name: Deploy Grafana to monitoring server
  hosts: monitoring
  become: true
  roles:
    - grafana
```