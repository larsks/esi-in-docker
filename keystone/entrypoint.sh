#!/bin/sh

: "${KEYSTONE_PUBLIC_HOSTNAME:="keystone"}"
: "${KEYSTONE_INTERNAL_HOSTNAME:="keystone"}"

set -e -x

rm -f /etc/httpd/conf.d/ssl.conf
chsh -s /bin/bash keystone

crudini --set /etc/keystone/keystone.conf database connection \
	"mysql+pymysql://keystone:$(cat /run/secrets/keystone-db-password)@database/keystone"
crudini --set /etc/keystone/keystone.conf token provider fernet

while ! su keystone -c 'keystone-manage db_sync'; do
	echo "failed to initialize database; retrying..."
	sleep 1
done

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password "$(cat /run/secrets/keystone-admin-password)" \
  --bootstrap-admin-url "http://${KEYSTONE_INTERNAL_HOSTNAME}:35357/v3/" \
  --bootstrap-internal-url "http://${KEYSTONE_INTERNAL_HOSTNAME}:5000/v3/" \
  --bootstrap-public-url "http://${KEYSTONE_PUBLIC_HOSTNAME}:5000/v3/" \
  --bootstrap-region-id RegionOne

ln -sf /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

mkdir -p /etc/openstack
cat > /etc/openstack/clouds.yaml <<EOF
clouds:
  openstack:
    auth:
      username: admin
      project_name: admin
      password: $(cat /run/secrets/keystone-admin-password)
      auth_url: http://${KEYSTONE_INTERNAL_HOSTNAME}:5000
      user_domain_name: Default
      project_domain_name: Default
    region: RegionOne
    identity_api_version: 3
    interface: public
EOF

exec "$@"
