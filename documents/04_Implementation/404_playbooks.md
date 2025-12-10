---
layout: default
title: 4.4 Playbook
parent: 4. Implementation
nav_order: 4
---

# 4.3 Ansible Playbooks

# Introduction


# Node Exporter

**Node Exporter Introduction text**


### Main task ```roles/node-exporter/tasks/main.yml``` 

Installs the Node Exporter files directly from the github, using the latest available version as of the time of writing this.

```yaml
---
# Download Node Exporter file
- name: Download Node Exporter
  get_url:
    url: https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
    dest: /tmp/node_exporter.tar.gz
    mode: '0755'
```

Once installed, the zipped file gets extracted into /tmp, so download packages can be automatically removed upon server restart.

```yaml
# Extract it
- name: Extract Node Exporter
  unarchive:
    src: /tmp/node_exporter.tar.gz
    dest: /tmp/
    remote_src: yes
```

The files are then moved into the /usr/local/bin, standard for Linux.

```yaml
# Move the binary to the right place
- name: Copy Node Exporter binary
  copy:
    src: /tmp/node_exporter-1.10.2.linux-amd64/node_exporter
    dest: /usr/local/bin/node_exporter
    mode: '0755'
    remote_src: yes
```

For security best pratice reasons, a Node Exporter user is created which only has permissions to read /proc and /sys (needed for metrics) and bind to the port 9100.

```yaml
# Create a user to run the Node Exporter (for security best practice)
- name: Create node_exporter user
  user:
    name: node_exporter
    shell: /bin/false       # Can't log in
    system: yes             # System user
    create_home: no         # No home directory needed
```

Creates a service file, so that the Node Exporter starts on boot, and the notify restarts it after creating the file.

```yaml
# Create systemd service file
- name: Create systemd service file
  template:
    src: node_exporter.service.j2
    dest: /etc/systemd/system/node_exporter.service
  notify: restart node_exporter
```

Stars the Node Exporter (during the task) and makes it start on boot - difference with the one above, is that the systemd wont ever 

```yaml
# Enable and start the service
- name: Start and enable Node Exporter
  systemd:
    name: node_exporter
    state: started
    enabled: yes
    daemon_reload: yes
```

### Handler ```roles/node-exporter/handlers/main.yml``` 
Handlers run when notified by a task, whenever the config file changes, it will restart the service.

```yaml
---
- name: restart node_exporter
  systemd:
    name: node_exporter
    state: restarted
    daemon_reload: yes
``` 

### Service Template ```roles/node-exporter/templates/node_exporter.service.j2```

This file tells the systemd (Ubuntu service maanger) how to run the Node Exporter.
In this case, it will wait for the network to be up before starting the service.

```ini
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
``` 

# Documentation References

## Node Exporter
- Installation: https://prometheus.io/docs/guides/node-exporter/
- GitHub: https://github.com/prometheus/node_exporter
- Latest Release: https://github.com/prometheus/node_exporter/releases/latest

## Prometheus
- Installation: https://prometheus.io/docs/prometheus/latest/installation/
- Configuration: https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- GitHub: https://github.com/prometheus/prometheus
- Latest Release: https://github.com/prometheus/prometheus/releases/latest

## Grafana
- Installation: https://grafana.com/docs/grafana/latest/setup-grafana/installation/debian/
- Configuration: https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/
- API Docs: https://grafana.com/docs/grafana/latest/developers/http_api/

## Project current setup:
- Binary locations: `/usr/local/bin/` (as per Prometheus docs)
- Config locations: `/etc/` (as per official docs)
- Data locations: `/var/lib/` (as per official docs)

