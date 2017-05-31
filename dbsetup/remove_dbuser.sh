#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: $0 <postgres_connection_string> <username> <db_to_revoke_access_to>"
    exit 1
fi

set -u
psqlConnectionString="$1"
userToRemove="$2"
dbToRevokeAccessTo="$3"


echo Rvoking permission to turn related tables
tablesToDrop=(turnusers_lt \
                turn_secret \
                allowed_peer_ip \
                denied_peer_ip \
                turn_origin_to_realm \
                turn_realm_option \
                oauth_key \
                admin_user \
)

echo Granting permissino to turn related tables
for i in ${tablesToDrop[@]};
do
    echo Droping $i ...
    psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "REVOKE ALL PRIVILEGES ON $i from $userToRemove;"
done


echo Removing user $userToRemove privs from $dbToRevokeAccessTo
psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "\
    REVOKE ALL PRIVILEGES ON DATABASE $dbToRevokeAccessTo FROM $userToRemove"

echo Droping user $userToRemove
psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "DROP ROLE $userToRemove;"

echo Done
