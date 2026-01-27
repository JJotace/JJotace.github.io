---
layout: default
title: 5.1 Summary & Reflection
parent: 5. Handover
nav_order: 1
---

# Summary & Reflection

## 1. Project Review

This project successfully delivered an automated server monitoring infrastructure using IaC principles. The implementation of Ansible as the automation platform, combined with Prometheus for metrics collection and Grafana for visualization, has improved the efficiency of the infrastructure deployment and monitoring. This monitoring solution allows for detailed insight in system resources and statistics across the different servers through a centralized dashboard.

The final product demonstrates that with proper automation a complete monitoring stack can be easily deployed to multiple servers with a single command. All components work together seamlessly, survive system reboots and ansible redeployments. It even restarts upon configuration change on its own.

## 2. Lessons Learnt

**Better infrastructure planning** could have prevented issues, like the confusion between AWS Linux and Ubuntu, or the private vs public IP networking problem which cost quite a bit of time to figure out.

**Documentation discipline** would have helped greatly with the project SMEs, not enough resources were put into it early on and it cost a lot of time to make up for it in the later sprints.

**Budget constrains** force better practices. The 50$ AWS limit made me more efficient and strategic about testing.

**Communication with stakeholders** is key. Earlier updates with the SMEs would have prevented missunderstandings and would have sped up the project by following their tips earlier, instead of during the end of the project, when almost everything was already done.

## 3. Final Assessment

The project has shown that automation is a vital part of a monitoring infrastructure, and that without one, managing and troubleshooting is practically impossible for larger scale infrastructures.

In the future, the data source and dashboard importing process could be optimized, so that it doesn't have to be added manually, as this goes against the principles of IaC. The project could also be expanded with application-level metrics and alerting systems. The current implementation serves as a solid foundation that can be extended with more features like high availability, backup strategies and advanced dashboard customization.

The project met all SMART objectives set at the beginning, with the automated deployment working properly, metrics flowing correctly from all target servers, and dashboards displaying real-time data. The documentation is thorough enough that anyone with basic Linux understanding could reproduce the entire setup.


## 4. Personal Summary

As with many IT projects, time management often proves to be one of the biggest challenges. Between a mix of suboptimal planning and unexpected probnlems, it was sometimes hard to manage staying on track with the schedule. Working with Ansible and new tools also took quite a bit of time to learn.

A main learning point for me from this project was communication and documentation. These two aren't my forte, as my SMEs probably figured out by now. In a complex technical project like this, it is essential to document and plan everything early on, but I jumped the gun and started working on the project before even being done with some of the basic planning and documentation from the first sprint. I should have taken my time to update the stakeholders of the process, and not leave them wondering how things are going, while seeing a fairly empty documentation.

The experience with security groups and AWS networking has helped me massively. Networking is a vital part of many projects and it is also one of my weaker points, so taking the time to study the infrastructure and plan following best practices has helped me better understand this part of IT that I don't often have to work with in my day to day.

This project has given me the confidence to tackle more complex tasks. The knowledge gained in automation, monitoring and troubleshooting will help me better support the shift to Grafana within my company, and maybe even automate some processes myself.

Personal life can get in the way of a project. I had to put in a lot of extra time to help balance personal, business and school life and be able to finish this project on time, but that has helped me learn how to give my everything and remain calm in stressful situations, specially against the clock.

All in all, even through the issues and stress, I am happy with everything I have learnt during this project, specially thanks to the useful links and information provided from the SMEs. I was able to present my project in a way I have never presented before, with more character, energy and most important of all, keeping it entertaining for the audience.