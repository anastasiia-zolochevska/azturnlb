#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <postgres_connection_string> <path_to_turnserver_sql_schema>"
    exit 1
fi

psqlConnectionString="$1"
sqlSchemaPath="$2"

set -u

echo "Attempting to initialize db for coturn...."
psql -v ON_ERROR_STOP=1 \
    "$psqlConnectionString" \
    -f "$sqlSchemaPath" \

echo Done
