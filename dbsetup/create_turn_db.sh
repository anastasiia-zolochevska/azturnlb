#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <postgres_connection_string> <db_name>"
    exit 1
fi

psqlConnectionString="$1"
dbName="$2"
sqlSchemaPath="$3"

set -u

echo "Attempting to create database..."
psql -v ON_ERROR_STOP=1 \
    "$psqlConnectionString" \
    -c "CREATE DATABASE $dbName;" \

echo Done
