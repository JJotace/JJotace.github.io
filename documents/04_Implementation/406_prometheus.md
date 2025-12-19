---
layout: default
title: 4.6 Prometheus
parent: 4. Implementation
nav_order: 6
---

# 4.6 Prometheus

Prometheus is the data collector and storage engine.
It does several things:

- Pulls metrics from target servers
- Stores the data locally
- Provides a web interface to query the data
- Sends the data to Grafana for visualization


# Playbooks

## Main Task

```roles/prometheus/tasks/main.yml```

```yaml
---
- name: Create prometheus system user
  user:
    name: prometheus
    system: true
    shell: /bin/false
    create_home: false

- name: Create /etc/prometheus directory
  file:
    path: /etc/prometheus
    state: directory
    owner: prometheus
    group: prometheus
    mode: '0755'

- name: Create /var/lib/prometheus directory
  file:
    path: /var/lib/prometheus
    state: directory
    owner: prometheus
    group: prometheus
    mode: '0755'

- name: Download prometheus binary
  get_url:
    url: "https://github.com/prometheus/prometheus/releases/download/v3.8.0/prometheus-3.8.0.linux-amd64.tar.gz"
    dest: /tmp/prometheus.tar.gz
    mode: '0644'

- name: Extract prometheus binary
  unarchive:
    src: /tmp/prometheus.tar.gz
    dest: /tmp
    remote_src: true
    creates: /tmp/prometheus-3.8.0.linux-amd64

- name: Copy prometheus binary to /usr/local/bin
  copy:
    src: /tmp/prometheus-3.8.0.linux-amd64/prometheus
    dest: /usr/local/bin/prometheus
    owner: prometheus
    group: prometheus
    mode: '0755'
    remote_src: true

- name: Copy promtool binary to /usr/local/bin
  copy:
    src: /tmp/prometheus-3.8.0.linux-amd64/promtool
    dest: /usr/local/bin/promtool
    owner: prometheus
    group: prometheus
    mode: '0755'
    remote_src: true

- name: Copy prometheus config template
  template:
    src: prometheus.yml.j2
    dest: /etc/prometheus/prometheus.yml
    owner: prometheus
    group: prometheus
    mode: '0644'
  notify: restart prometheus

- name: Install prometheus systemd service
  template:
    src: prometheus.service.j2
    dest: /etc/systemd/system/prometheus.service
    owner: root
    group: root
    mode: '0644'
  notify: restart prometheus

- name: Start and enable prometheus service
  systemd:
    name: prometheus
    state: started
    enabled: true
    daemon_reload: true

- name: Clean up prometheus tar file
  file:
    path: /tmp/prometheus.tar.gz
    state: absent

- name: Clean up extracted prometheus directory
  file:
    path: /tmp/prometheus-3.8.0.linux-amd64
    state: absent
```

## Templates

### ```roles/prometheus/templates/prometheus.yml.j2```


```yaml
# Prometheus configuration file
# Defines what to monitor and how often


global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'infrastructure-monitoring'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: 'monitoring-server'

  - job_name: 'node-exporter'
    static_configs:
      - targets:
{% for host in groups['targets'] %}
          - '{{ hostvars[host].ansible_host }}:9100'
{% endfor %}
```

### ```roles/prometheus/templates/prometheus.service.j2```

This file does several things.

- Describing the process
- Prometheus starts after the network is ready
- 

```ini
[Unit]
Description=Prometheus Monitoring System
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --storage.tsdb.retention.time=24h \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090

Restart=always
RestartSec=5
```


# Documentation References

- Guide: https://prometheus.io/docs/introduction/overview/
- GitHub: https://github.com/prometheus/prometheus
- Latest Release: https://github.com/prometheus/prometheus/releases/latest
- Systemd documentation: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html?__goaway_challenge=meta-refresh&__goaway_id=56a163db49b5f793713314165e744b91&__goaway_referer=https%3A%2F%2Fclaude.ai%2F


### Prometheus Handler - main.yml

---
- name: restart prometheus
  systemd:
    name: prometheus
    state: restarted
    daemon_reload: yes
