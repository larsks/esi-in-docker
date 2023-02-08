#!/bin/sh

mysql -u root -h database mysql <<EOF
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
  IDENTIFIED BY '$(cat /run/secrets/keystone-db-password)';
EOF
