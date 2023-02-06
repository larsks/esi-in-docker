#!/bin/sh

cat > $HOME/.my.cnf <<EOF
[client]
password=$(cat /run/secrets/mariadb-root-password)
EOF
chmod 600 $HOME/.my.cnf

