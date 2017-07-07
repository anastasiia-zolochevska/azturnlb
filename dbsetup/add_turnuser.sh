#!/bin/sh

set -e

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    echo "Usage: $0 <postgres_connection_string> <sharedSecret> <realm>"
    exit 1
fi

set -u
psqlConnectionString="$1"
sharedSecret="$2"
realm="$3"

docker run --rm zolochevska/3drelayadmin:latest -e "$psqlConnectionString" -a -s $sharedSecret -r $realm

echo Done
