#!/bin/sh

exec mysql --defaults-extra-file=/dev/stdin -u root mysql -e "select 1" <<EOF
[client]
password=$(cat /run/secrets/mariadb-root-password)
EOF
