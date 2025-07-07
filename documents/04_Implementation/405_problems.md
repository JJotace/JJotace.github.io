---
layout: default
title: 4.5 Problems
parent: 4. Implementation
nav_order: 5
---

# 4.5 Problems

In this part of the project, the issues and troubles that were encountered during the implementation phase are briefly introduced, explaining how these were fixed if possible.

## DB Controller Password

The password could not be hardcoded within the playbook for security reasons. 
This complicated things quite a bit for me for a while, since I was unsure on how to go about solving this problem.

There were a few options that my colleagues recommended me.
The first one being to install a certificate containing the password locally into the ansible controllers, so that they would only need to run the command locally and save the output. Of course, if this would have been this easy I wouldn't be adding it to this section of the project.
Ansible controllers can't obtain root to run commands locally, which the command to reveal the certificate password needs. The only way would be to connect to a different server and obtain root there.

For every environment, we have more than one ansible controller, which contain the exact same data. The second idea, was to use a special host list file within the controllers in which I could specify an ansible controller to use. I would just have to specify a different ansible controller within the host list.
This did not work at all. Everytime the playbook was executed, it would fail throwing a host list error, indicating that it was empty.

Now the next option would be to create a certificate within an application server. This involved asking developers in charge of their respective applications if I could use the server for this activity. Luckily this was the least of my problems as everybody seemed to be happy to help !

This was the final solution, now for every environment there is one server with a certificate installed, which gets accessed by the ansible controller as root and reads and copies the password.

This whole situation cost a lot of time to figure out and fix for the project.

### Password logging

While testing the playbook, the password for the database collector was being logged within the output of the order with a debugging task. This made making sure everything was being correctly saved easy, but whenever this part of the code was removed after the initial testing phase, the password stopped getting set into the collector.

After some testing, I added a "no_log" condition at the end of the debugging, and set it to true, so that it would not show up in the output.
This seemed to fix the issue.

```yaml
  - name: Debug password
    debug:
     var: passwort
    no_log: true
```
{% endraw %}



## Changes in Company Structure

### Keystore path changes


### New Ansible Controllers