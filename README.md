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

Steps
-----

1. Clone the repository to your local system
```
git clone https://github.com/mrobson/openstackupi-openshift.git
```

2. Log into your account at the [RedHat Cloud Managment Portal](//cloud.redhat.com/openshift/install/metal/user-provisioned/) and download the user provisioned baremetal openshift-install binary

3. Untar and move the downloaded binary to the root directory of the cloned openstackupi-openshift project
```
tar zxvf openshift-install-linux-4.1.4.tar.gz
mv openshift-install-linux-4.1.4 ~/openstackupi-openshift/openshift-install
```

4. Create your openstack-upi-install-config.yml file
    - Set your baseDomain
    - Set your cluster name
    - Set your pullSecret
    - Set your sshKey

```yaml
apiVersion: v1
baseDomain: <base_domain>
compute:
- name: worker
  platform: {}
  replicas: 3
controlPlane:
  name: master
  platform: {}
  replicas: 3
metadata:
  name: <cluster_name>
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostSubnetLength: 9
  machineCIDR: 10.0.0.0/16
  serviceCIDR: 172.30.0.0/16
  type: OpenShiftSDN
platform:
  none: {}
pullSecret: '<pull secret>'
sshKey: |
  ssh-rsa <key>
```
