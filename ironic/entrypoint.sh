#!/bin/sh

: "${KEYSTONE_INTERNAL_URL:=http://keystone:5000}"
: "${KEYSTONE_PUBLIC_URL:=http://keystone:5000}"
: "${IRONIC_INTERNAL_URL:=http://ironic:6385}"
: "${IRONIC_PUBLIC_URL:=http://ironic:6385}"
: "${IRONIC_KEYSTONE_PASSWORD:="$(cat /run/secrets/ironic-keystone-password)"}"
: "${IRONIC_DB_PASSWORD:="$(cat /run/secrets/ironic-db-password)"}"

set -e -x

crudini --set /etc/ironic/ironic.conf database connection \
	"mysql+pymysql://ironic:${IRONIC_DB_PASSWORD}@database/ironic"
crudini --set /etc/ironic/ironic.conf DEFAULT auth_strategy keystone
crudini --set /etc/ironic/ironic.conf keystone_authtoken auth_type password
crudini --set /etc/ironic/ironic.conf keystone_authtoken auth_url "${KEYSTONE_INTERNAL_URL}"
crudini --set /etc/ironic/ironic.conf keystone_authtoken www_authenticate_uri "${KEYSTONE_PUBLIC_URL}"
crudini --set /etc/ironic/ironic.conf keystone_authtoken username ironic
crudini --set /etc/ironic/ironic.conf keystone_authtoken password "${IRONIC_KEYSTONE_PASSWORD}"
crudini --set /etc/ironic/ironic.conf keystone_authtoken project_name service
crudini --set /etc/ironic/ironic.conf keystone_authtoken project_domain_name Default
crudini --set /etc/ironic/ironic.conf keystone_authtoken user_domain_name Default
crudini --set /etc/ironic/ironic.conf keystone_authtoken service_token_roles_required true
crudini --set /etc/ironic/ironic.conf keystone_authtoken memcached_servers cache

ironic-dbsync upgrade

sh /scripts/common/configure-clouds-yaml.sh
sh /scripts/common/wait-for-keystone.sh
sh /scripts/common/create-service-user.sh ironic "${IRONIC_KEYSTONE_PASSWORD}"
sh /scripts/common/register-service.sh baremetal ironic "${IRONIC_INTERNAL_URL}" "${IRONIC_PUBLIC_URL}"

exec "$@"
