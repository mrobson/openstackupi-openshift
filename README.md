OpenShift 4.1: Fully Automated UPI on OpenStack
===============================================
Author: Matt Robson

Technologies: OpenShift 4.1, OpenStack 14, Ansible

Product: Cloud

Breakdown
---------
This is a fully automated, self-contained, OpenShift 4 Baremetal UPI deployment on OpenStacki 14. The playbooks build your OpenStack project and all of the necessary resources to standup OpenShift 4.1.

For more information see:

* <https://docs.openshift.com/container-platform/4.1/installing/installing_bare_metal/installing-bare-metal.html#installing-bare-metal/> for more information on the baremetal install process

System Requirements
-------------------
Before building out your cluster, you will need:
* openshift-install binary
* anible
* oc and kubectl binary

Prerequisites
-------------
* openstack installed
* openstack admin account
* openshift pull secret
