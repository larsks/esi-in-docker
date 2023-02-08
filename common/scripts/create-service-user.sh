#!/bin/sh

set -x
openstack project create service --or-show
openstack user create "$1" --or-show --project service --password "$2"
openstack role add --user "$1" --project service admin
