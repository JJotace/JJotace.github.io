---
layout: default
title: 4.7 Grafana
parent: 4. Implementation
nav_order: 7
---

# 4.7 Grafana



# Playbooks

## Main Task ```roles/grafana/tasks/main.yml```

Installs the package needed to allow Ubuntu to download packages over HTTPs.

```yaml
---
- name: Install apt-transport-https
  apt:
    name: apt-transport-https
    state: present
    update_cache: yes
```

Adds Grafana's GPG key, which verifies packages are safe.

```yaml
- name: Add Grafana GPG key
  apt_key:
    url: https://apt.grafana.com/gpg.key
    state: present
```

Tells the system where to download Grafana from.

```yaml
- name: Add Grafana repository
  apt_repository:
    repo: deb https://apt.grafana.com stable main
    state: present
```

Installs Grafana, which unlike Prometheus or Node Exporter, uses Ubuntu's package manager.

```yaml
- name: Install Grafana
  apt:
    name: grafana
    state: present
    update_cache: yes
```

Deploys the Grafana configuration file from the template. Notify restarts it in case of configuration changes.

```yaml
- name: Deploy Grafana configuration
  template:
    src: grafana.ini.j2
    dest: /etc/grafana/grafana.ini
    owner: root
    group: grafana
    mode: '0640'
  notify: restart grafana
```

Starts Grafana and sets it to start on boot. It is accessible under http://monitoring-server-ip:3000

```yaml
- name: Start and enable Grafana service
  systemd:
    name: grafana-server
    state: started
    enabled: yes
```

## Grafana Configuration Template ```roles/grafana/templates/grafana.ini.j2```

This templates configures basic settings such as the default user and password, which can later be changed once logged in, and the port in which it runs. It also counts with some security settings to not allow anyone to create users, and requires login to view the dashboards.

```ini
[server]
http_port = 3000
domain = localhost

[security]
admin_user = admin
admin_password = admin

[database]
type = sqlite3

[users]
allow_sign_up = false

[auth.anonymous]
enabled = false

[log]
mode = console file
level = info
```

## Grafana Handler ```roles/grafana/handlers/main.yml```

Handlers run when notified by a task. Whenever the configuration file changes, this restarts Grafana to apply the new settings.

```yaml
---
- name: restart grafana
  systemd:
    name: grafana-server
    state: restarted
```

# Documentation References

- Official Guide: https://grafana.com/docs/grafana/latest/
- Installation: https://grafana.com/docs/grafana/latest/setup-grafana/installation/
- Dashboard Gallery: https://grafana.com/grafana/dashboards/
- Node Exporter Dashboard: https://grafana.com/grafana/dashboards/1860