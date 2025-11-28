---
layout: default
title: 3.3 SWOT Analysis
parent: 3. Planning
nav_order: 3
---

# 3.3 SWOT Analysis

<table>
<tr>
<td width="50%" valign="top">

### Strengths

- IaC with Ansibles enables fast and reproducible rebuilds
- Automation reduces manual errors
- Scalable solution via inventory file
- Cost efficiency through optimized resource usage (t2.micro/small)
- Using widely adopted industry standard tools
- Documented so that anyone can follow and reproduce the same results

</td>
<td width="50%" valign="top">

### Weaknesses

- Almost from scratch learning of new tools
- Single point of failure with monitoring server
- Manual AWS infrastructure provisioning required
- Basic security features
- No alerting when something breaks
- Dependency on AWS-specific features

</td>
</tr>
<tr>
<td width="50%" valign="top">

### Opportunities

- Could be extended with other components such as databases etc.
- Integration of alert notifications
- AWS part could be automated with Terraform
- High availability setup with clustered architecture
- Implementation of service discovery

</td>
<td width="50%" valign="top">

### Threats

- Limited AWS student budget ($50)
- Security vulnerabilities in public-facing services
- IP address changes requiring frequent security group changes
- Data loss risk without backups
- Technology changes and breaking updates
- Time management challenges

</td>
</tr>
</table>