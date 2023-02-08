#!/bin/sh

while ! openstack catalog list > /dev/null 2>&1; do
	echo "waiting for keystone"
	sleep 1
done
