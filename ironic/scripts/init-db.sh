#!/bin/sh

mysql -u root -h database mysql <<EOF
CREATE DATABASE IF NOT EXISTS ironic;
GRANT ALL PRIVILEGES ON ironic.* TO 'ironic'@'%' \
  IDENTIFIED BY '$(cat /run/secrets/ironic-db-password)';
EOF
