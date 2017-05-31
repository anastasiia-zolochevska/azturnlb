#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "Usage: $0 <postgres_connection_string> <username> <password> <db_to_give_access_to>"
    exit 1
fi

set -u

psqlConnectionString="$1"
userToAdd="$2"
userPassword="$3"
dbToGiveAccessTo="$4"

echo Adding user $userToAdd to $dbToGiveAccessTo
psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "CREATE ROLE $userToAdd WITH NOCREATEDB NOCREATEROLE LOGIN PASSWORD '$userPassword'"

psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "\
    GRANT ALL PRIVILEGES ON DATABASE $dbToGiveAccessTo TO $userToAdd"

tablesToDrop=(turnusers_lt \
                turn_secret \
                allowed_peer_ip \
                denied_peer_ip \
                turn_origin_to_realm \
                turn_realm_option \
                oauth_key \
                admin_user \
)

echo Granting permission to turn related tables
for i in ${tablesToDrop[@]};
do
    echo Droping $i ...
    psql -v ON_ERROR_STOP=1 "$psqlConnectionString" -c "GRANT ALL PRIVILEGES ON $i to $userToAdd;"
done



echo Done
