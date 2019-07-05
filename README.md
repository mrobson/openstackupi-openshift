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

5. The `baseDomain` and cluster `name` form the domain for the cluster
    - `baseDomain: mattshift.lab`
    - `name: mrobson`
    - `domain: mrobson.mattshift.lab`
    - Example: `master-0.mrobson.mattshift.lab`

6. From the `openstack-openshift-playbook` directory, configure the variables needed for the installation. The playbooks will create 

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
# update the /etc/hosts file for cli and console resolution
update_hosts: true
# run the role to wait for bootstrap and the install to complete - requires local machine to be able hit the API loadbalancer
wait_for_complete: true
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
# name of the flavor to create for the masters
master_flavor_name: ocpmaster
# name of the flavor to create for the workers
worker_flavor_name: ocpworker
# name of coreos image - suggest using fully qualified release naming
coreos_image_name: rhcos-410.8.20190520.1
# location of CoreOS qcow2 image
coreos_image_location: /Users/matthewrobson/Downloads/rhcos-410.8.20190520.1-openstack.qcow2
# flavor for apiserver
apiserver_flavor: CentOS7
# name of the private network for the openshift cluster
network_name: ocp4_network
# name of the private subnet for the openshift cluster
subnet_name: ocp4_subnet
# subnet address for the openshift cluster
subnet: 10.10.11
# cidr for the openshift cluster subnet
cidr: /24
# name of the openshift cluster network router
router_name: ocp4_router
# name of the external openstack network
external_network_name: public
# flag to also remove the CoreOS image and OCP flavors 
remove_image_and_flavors: false
```

7. Setup the ansible hosts file for the flavor, image and fixed_ip (private openstack subnet) you configured above

```
[utility]

[apiserver]
api flavor=ocpworker ignfile=empty.ign image=CentOS7 floating_ip=true fixed_ip=10.10.11.10 ansible_connection=local

[openshift]
bootstrap flavor=ocpmaster ignfile=bootstrap-append.ign image=rhcos-410.8.20190520.1 floating_ip=true fixed_ip=10.10.11.30 ansible_connection=local
master-0 flavor=ocpmaster ignfile=master.ign image=rhcos-410.8.20190520.1 floating_ip=true fixed_ip=10.10.11.31 ansible_connection=local
master-1 flavor=ocpmaster ignfile=master.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.32 ansible_connection=local
master-2 flavor=ocpmaster ignfile=master.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.33 ansible_connection=local
worker-0 flavor=ocpworker ignfile=worker.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.34 ansible_connection=local
worker-1 flavor=ocpworker ignfile=worker.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.35 ansible_connection=local
worker-2 flavor=ocpworker ignfile=worker.ign image=rhcos-410.8.20190520.1 fixed_ip=10.10.11.36 ansible_connection=local

[openstack]
localhost ansible_connection=local

[uninstall:children]
apiserver
openshift
```

8. Run the playbook

If you set `update_hosts: true`, you need to use `-K` and provide the sudo password for your local machine so it can update the hosts file with entries for the apiserver, console and oauth addresses

> ansible-playbook -i hosts -K site.yml

If you do not want to updateb your hosts file, set `update_hosts: false` in `group_vars/all` and do not use the `-K` flag

The playbook runtime to an install-complete OpenShift cluster, without having to upload and create the CoreOS image, is about 50 minutes

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
    - `apiserver.yml`: Creates and configures the apiserver for the environment - osp api instance with external access, private dns server and haproxy loadbalancer for openshift. It also updates the `/etc/hosts` file of your localhost for API access if you set `update_hosts: true` in `group_vars/all`
      - role: `apiserver`
      - role: `hosts` conditional: `update_hosts: true`
      - role: `bind`
      - role: `loadbalancer`
    - `openshift.yml`: Creates the openshift environment - static port allocations, 7 instances and any required floating ips for external access - bootstrap, master0-2, worker0-2
      - role: `openshift`
      - role: `waitforcomplete` conditional: `wait_for_complete: true`

The uninstall playbook has 1 role

3. Uninstall Playbook
    - `uninstall.yml`: Deletes all of the instances, floating ips, port allocations, router, subnet, network, user and project. Does not remove the CoreOS image or flavors by default. If you want to remove them as well, set `remove_image_and_flavors: true` in `group_vars/openstack`
      - role: `uninstall`

API and Console Access
----------------------

If you do not have proper name resolution from your local machine, you can setup your local hosts file for console and cli access. With `update_hosts: true` and sudo access, this will be updated automatically.

```
<apiserver_public_ip>    api.mrobson.mattshift.lab
<apiserver_public_ip>    console-openshift-console.apps.mrobson.mattshift.lab
<apiserver_public_ip>    oauth-openshift.apps.mrobson.mattshift.lab
```

CLI Access
----------

From the `openstackupi-openshift` directory - Note: the preflight role will copy the current kubeconfig to `~/.kube/config`

> export KUBECONFIG=./installer/auth/kubeconfig

> oc whoami
```
system:admin
```

Checking Cluster Install Status
-------------------------------

If you have access to the API loadbalancer and set `wait_for_complete: true`, these steps will be executed as part of the `waitforcomplete` role

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

Registry Storage
----------------

If you have access to the API loadbalancer and set `wait_for_complete: true`, this step will be executed as part of the `waitforcomplete` role

The install will not complete, waiting on the image registry, if you do not modify the operator to change the storgae to be epmemeral

> oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'


Uninstall
---------

This removes the entire OpenShift cluster and all of the openstack objects except for the CoreOS image and master/worker flavors. If you want to remove the image and flavors as well, set `remove_image_and_flavors: true` in `group_vars/openstack`

> ansible-playbook -i hosts uninstall.yml

The uninstall playbook takes about 2 minutes to remove everything
