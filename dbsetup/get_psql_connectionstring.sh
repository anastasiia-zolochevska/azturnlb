#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: $0 <psql_servername> <psql_username> <psql_password> [<psql_dbname>]"
    exit 1
fi

dbname=postgres

if [[ -n "$4" ]]; then
   dbname=$4
fi
servername=$1
username=$2
password=$3

set -u
echo host=$servername.postgres.database.azure.com dbname=$dbname user=$username@$servername password=$password connect_timeout=30 sslmode=require port=5432
