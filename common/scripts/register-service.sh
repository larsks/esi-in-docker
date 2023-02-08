#!/bin/sh

openstack service create --name "$2" "$1"
openstack endpoint create "$1" internal "$3"
openstack endpoint create "$1" public "$4"
