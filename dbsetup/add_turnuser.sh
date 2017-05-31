#!/bin/sh

set -e

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "Usage: $0 <postgres_connection_string> <username> <password> <realm>"
    exit 1
fi

set -u
psqlConnectionString="$1"
userToAdd="$2"
userPassword="$3"
realm="$4"

docker run --rm obsoleted/3drelayadmin:v0.0.1a -e "$psqlConnectionString" -a -u $userToAdd -p $userPassword -r $realm

echo Done
