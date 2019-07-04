OpenShift 4.1: Fully Automated UPI on OpenStack
===============================================
Author: Matt Robson

Technologies: OpenShift 4.1, OpenStack 14, Ansible

Product: Cloud

Breakdown
---------
This is a fully automated, self-contained, OpenShift 4 Baremetal UPI deployment on OpenStacki 14. The playbooks build your OpenStack project and all of the necessary resources to standup OpenShift 4.1.

For more information see:

* [OpenShift 4.1 Baremetal UPI Documentation](https://docs.openshift.com/container-platform/4.1/installing/installing_bare_metal/installing-bare-metal.html#installing-bare-metal/)

System Requirements
-------------------

Before building out your cluster, you will need

* `openshift-install` binary
* ansible
* `oc` binary

Prerequisites
-------------
* openstack installed
* openstack admin account
* openshift pull secret

Steps
-----

1. Clone the repository to your local system

> git clone https://github.com/mrobson/openstackupi-openshift.git

2. Log into your account at the [RedHat Cloud Managment Portal](https://cloud.redhat.com/openshift/install/metal/user-provisioned/) and download the user provisioned baremetal openshift-install binary

3. Untar and move the downloaded binary to the root directory of the cloned `openstackupi-openshift` project

> tar zxvf openshift-install-system-version.tar.gz

> mv openshift-install-system-version /path/to/openstackupi-openshift/openshift-install

4. Create your `openstack-upi-install-config.yml` file
    - Set your `baseDomain`
    - Set your cluster `name`
    - Set your `pullSecret`
    - Set your `sshKey`

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

5. The `baseDomain` and cluster `name` form your full domain for the cluster
    - `baseDomain: mattshift.lab`
    - `name: mrobson`
    - `full domain: *.mrobson.mattshift.lab`
    - `master-0.mrobson.mattshift.lab`

6. From the `openstack-openshift-playbook` directory, configure your group variables for the installation

> vi group_vars/all

```Text
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

> vi group_vars/openstack

```Text
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

7. Setup the ansible hosts file for the flavor, image and fixed_ip (private openstack network) for your openshift cluster

```
[utility]

[apiserver]
api flavor=ocpcompute ignfile=empty.ign image=CentOS7 floating_ip=true fixed_ip=10.10.11.10 ansible_connection=local

[openshift]
bootstrap flavor=ocpcontroller ignfile=bootstrap-append.ign image=rhcos-410.8.20190520.1 floating_ip=true fixed_ip=10.10.11.30 ansible_connection=local
master-0 flavor=ocpcontroller ignfile=master.ign image=rhcos-410.8.20190520.1 floating_ip=true fixed_ip=10.10.11.31 ansible_connection=local
master-1 flavor=ocpcontroller ignfile=master.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.32 ansible_connection=local
master-2 flavor=ocpcontroller ignfile=master.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.33 ansible_connection=local
worker-0 flavor=ocpcompute ignfile=worker.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.34 ansible_connection=local
worker-1 flavor=ocpcompute ignfile=worker.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.35 ansible_connection=local
worker-2 flavor=ocpcompute ignfile=worker.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.36 ansible_connection=local

[openstack]
localhost ansible_connection=local

[uninstall:children]
apiserver
openshift
```

8. Run the setup and installation playbook

> ansible-playbook -i hosts site.yml

Playbooks
---------

The setup and installation master playbook consists of 4 playbooks with 6 roles

1. Install Master Playbook: This imports the 4 main playbooks for the setup and install
    - `site.yml`

2. Install Playbooks
    - `preflight.yml`: Checks some prerequisites and generates fresh ignition configs for the installation
      - role: `preflight`
    - `openstack.yml`: Builds the openstack environment - project, quotas, user, roles, flavors, keypair, security groups, network, subnet and router
      - role: `openstack`
    - `apiserver.yml`: Creates and configures the apiserver for the environment - osp api instance with external access, private dns server and haproxy loadbalancer for openshift
      - role: `apiserver`
      - role: `bind`
      - role: `loadbalancer`
    - `openshift.yml`: Creates the openshift environment - static port allocations, 7 instances and any required floating ips for external access - bootstrap, master0-2, worker0-2
      - role: `openshift`

The uninstall playbook has 1 role

3. Uninstall Playbook
    - `uninstall.yml`: Deletes all of the instances, floating ips, port allocations, router, subnet, network, user and project
      - role: `uninstall`

API and Console Access
----------------------

If you do not have proper name resolution from your local machine, you can setup your local hosts file for console and cli access

```
<apiserver_public_ip>    api.mrobson.mattshift.lab
<apiserver_public_ip>    console-openshift-console.apps.mrobson.mattshift.lab
<apiserver_public_ip>    oauth-openshift.apps.mrobson.mattshift.lab
```

CLI Access
----------

From the `openstackupi-openshift` directory

> export KUBECONFIG=./installer/auth/kubeconfig

> oc whoami
```
system:admin
```

Checking Cluster Install Status
-------------------------------

From the `openstackupi-openshift` directory

> ./openshift-install --dir=installer wait-for bootstrap-complete

```
INFO Waiting up to 30m0s for the Kubernetes API at https://api.mrobson.mattshift.lab:6443...
INFO API v1.13.4+838b4fa up
INFO Waiting up to 30m0s for bootstrapping to complete...
INFO It is now safe to remove the bootstrap resources
```

> ./openshift-install --dir=installer wait-for install-complete

```
INFO Waiting up to 30m0s for the cluster at https://api.mrobson.mattshift.lab:6443 to initialize...
INFO Waiting up to 10m0s for the openshift-console route to be created...
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/path/to/openstackupi-openshift/installer/auth/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.mrobson.mattshift.lab
INFO Login to the console with user: kubeadmin, password: <password>
```

Uninstall
---------

This removes the entire OpenShift cluster and all of the openstack objects

> ansible-playbook -i hosts uninstall.yml
