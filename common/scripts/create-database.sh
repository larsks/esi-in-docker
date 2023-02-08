#!/bin/sh

set -e

sh /scripts/common/create-my-cnf.sh
sh /scripts/common/wait-for-db.sh

mysql -u root -h database mysql <<EOF
CREATE DATABASE IF NOT EXISTS $1;
GRANT ALL PRIVILEGES ON $1.* TO '$2'@'%' \
  IDENTIFIED BY '$(cat "$3")';
EOF
