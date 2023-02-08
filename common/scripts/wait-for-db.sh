#!/bin/sh

while ! mysql -u root -h database -e 'select 1' > /dev/null 2>&1; do
	echo "waiting for database"
	sleep 1
done
