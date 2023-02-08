#!/bin/sh

: "${KEYSTONE_INTERNAL_URL:=http://keystone:5000}"
: "${KEYSTONE_PUBLIC_URL:=http://keystone:5000}"
: "${KEYSTONE_ADMIN_PASSWORD:="$(cat /run/secrets/keystone-admin-password)"}"
: "${KEYSTONE_DB_PASSWORD:="$(cat /run/secrets/keystone-db-password)"}"

set -e -x

rm -f /etc/httpd/conf.d/ssl.conf
chsh -s /bin/bash keystone

crudini --set /etc/keystone/keystone.conf database connection \
	"mysql+pymysql://keystone:$KEYSTONE_DB_PASSWORD@database/keystone"
crudini --set /etc/keystone/keystone.conf token provider fernet

while ! su keystone -c 'keystone-manage db_sync'; do
	echo "failed to initialize database; retrying..."
	sleep 1
done

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password "$KEYSTONE_ADMIN_PASSWORD" \
  --bootstrap-internal-url "${KEYSTONE_INTERNAL_URL}/v3" \
  --bootstrap-public-url "${KEYSTONE_PUBLIC_URL}/v3" \
  --bootstrap-region-id RegionOne

ln -sf /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

cat > /config/clouds.yaml <<EOF
clouds:
  openstack-internal:
    auth:
      username: admin
      project_name: admin
      password: $KEYSTONE_ADMIN_PASSWORD
      auth_url: $KEYSTONE_INTERNAL_URL
      user_domain_name: Default
      project_domain_name: Default
    interface: internal
    region: RegionOne
    identity_api_version: 3
    interface: public
  openstack-public:
    auth:
      username: admin
      project_name: admin
      password: $KEYSTONE_ADMIN_PASSWORD
      auth_url: $KEYSTONE_PUBLIC_URL
      user_domain_name: Default
      project_domain_name: Default
    interface: public
    region: RegionOne
    identity_api_version: 3
    interface: public
EOF

mkdir -p /etc/openstack
ln -sf /config/clouds.yaml /etc/openstack/clouds.yaml

exec "$@"
