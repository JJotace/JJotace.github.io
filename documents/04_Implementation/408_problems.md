---
layout: default
title: 4.8 Problems
parent: 4. Implementation
nav_order: 8
---

# 4.8 Problems


## Wrong OS selected for Template

Something that took a few hours and breaks to figure out, was that the AWS AMI version of Linux uses a different default user than ubuntu.

This caused me to think there was a problem with my key pair, and after a whole lot of research and back and forth trying to create new key pairs and ensure everything should work, I noticed my templates were creating the instances with a different OS than initially planned.

AWS uses **ec2-user** while Ubuntu uses **ubuntu**

Once the right OS was used, the pings worked without issue.

Login command example:
ssh -i ~/.ssh/aws-key.pem ec2-user@<ip>

frost@Hitman:~/SEM02$ ansible all -m ping
monitoring-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
target-server-2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
target-server-1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}


## Private vs Public IP

Another issue that came along while testing, is that Prometheus uses the Private IP of the servers to work, and my inventory only counted with the Public IPs, so it was not able to communicate with the target servers, and showed as them being down

frost@Hitman:~/SEM02$ ansible monitoring -m shell -a "curl -s http://localhost:9090/api/v1/targets | grep -o '\"health\":\"[^\"]*\"'
monitoring-server | CHANGED | rc=0 >>
"health":"down"
"health":"down"
"health":"up"


After updating my inventory and the prometheus.yml.j2 template to use the Private IPs instead, it fixed the issue.

  - job_name: 'node-exporter'
    static_configs:
      - targets:
{% for host in groups['targets'] %}
          - '{{ hostvars[host].private_ip }}:9100'
{% endfor %}