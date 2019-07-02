#!/bin/bash

rm -rf installer
mkdir installer
cp openstack-upi-install-config.yml installer/install-config.yaml
./openshift-install --dir=./installer create ignition-configs
mv ./installer/bootstrap.ign ./openstack-openshift-playbook/roles/loadbalancer/files/bootstrap.ign
mv ./installer/master.ign ./openstack-openshift-playbook/roles/ocpinstances/files/master.ign
mv ./installer/worker.ign ./openstack-openshift-playbook/roles/ocpinstances/files/worker.ign
