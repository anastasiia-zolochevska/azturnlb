#!/bin/sh

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <postgres_connection_string>"
    exit 1
fi

psqlConnectionString="$1"

tablesToDrop=(turnusers_lt \
                turn_secret \
                allowed_peer_ip \
                denied_peer_ip \
                turn_origin_to_realm \
                turn_realm_option \
                oauth_key \
                admin_user \
)

set -u

echo Droping tables used by coturn
for i in ${tablesToDrop[@]};
do
    echo Droping $i ...
    psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "DROP TABLE IF EXISTS $i"
done
echo Done


