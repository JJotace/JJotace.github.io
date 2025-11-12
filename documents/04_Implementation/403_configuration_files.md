---
layout: default
title: 4.3 Configuration Files
parent: 4. Implementation
nav_order: 3
---

# 4.3 Configuration Files

## Introduction

## Configuration Files

### Ansible-Configuration (`ansible.cfg`) 
```ini
[defaults]
inventory = inventory.yml
host_key_checking = False
retry_files_enabled = False

[privilege_escalation]
become = True
```

### Inventory File (`inventory.yml`)
 ```yaml
---
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/aws-monitoring-key.pem
    ansible_python_interpreter: /usr/bin/python3

  children:
    monitoring: # Monitoring server group
      hosts:
        monitoring-server:
          ansible_host: <MONITORING_SERVER_PUBLIC_IP>

    targets: # Target servers group
      hosts:
        target-server-1:
          ansible_host: <TARGET_SERVER_1_PUBLIC_IP>
        target-server-2:
          ansible_host: <TARGET_SERVER_2_PUBLIC_IP>
```

### Main Playbook (`main.yml`)
```yaml
---
- name: Deploy Node Exporter to target servers
  hosts: targets
  roles:
    - node-exporter

- name: Deploy Prometheus to monitoring server
  hosts: monitoring
  roles:
    - prometheus

- name: Deploy Grafana to monitoring server
  hosts: monitoring
  roles:
    - grafana
```


## Monitoring Server Setup
