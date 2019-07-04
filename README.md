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
tar zxvf openshift-install-<system>-<version>.tar.gz
mv openshift-install-<system>-<version> /path/to/openstackupi-openshift/openshift-install
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

5. The baseDomain and cluster name form your full domain for your cluster
    - baseDomain: mattshift.lab
    - name: mrobson
    - full domain: *.mrobson.mattshift.lab
    - master-0.mrobson.mattshift.lab

6. Configure your the group variable for the installation
    - group_vars/all
```
# sudo user for the apiserver instance
user: centos
# forward domain for the cluster
fwd_domain: mrobson.mattshift.lab
# reverse domain for the cluster
rev_domain: 11.10.10.in-addr.arpa
# wildcard domain for the cluster
wild_domain: apps.mrobson.mattshift.lab
# forwarder to access the internet for your prviate DNS server
forward_dns: 10.5.30.45
```
    - group_vars/openstack
```
# openstack auth URL
auth_url:  http://<ip>:<port>
# openstack cluster admin user
adminuser: admin
# openstack cluster admin password
adminpass: password
# openstack user domain
user_domain: Default
# openstack project domain
project_domain: default
# openstack region
region: regionOne
# openstack auth api version
auth_api: 3
# openstack admin project name
adminproject: admin
# name of project to create for openshift cluster
project: mrobsonocp4
# name of user to create for openshift cluster project
ospuser: user
# password for openshift cluster project user
osppassword: password
# email for openshift cluster project user
email: address@adminuser.com
# ssh key for openshift cluster project keypair
ssh_key: /path/to/.ssh/id_rsa.pub
# name of the private network for the openshift cluster
network_name: ocp4_network
# name of the private subnet for the openshift cluster
subnet_name: ocp4_subnet
# first 3 octets of the subnet address for the openshift cluster
subnet: 10.10.11
# cidr for the openshift cluster subnet
cidr: /24
# name of the openshift cluster network router
router_name: ocp4_router
# name of the external openstack network
external_network_name: pubic
```

