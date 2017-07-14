#!/bin/sh

set -e

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: $0 <postgres_connection_string> <secret> <realm> <relayadmin_docker_image>"
    exit 1
fi

set -u
psqlConnectionString="$1"
secret="$2"
realm="$3"
dockerimage=${4:-"zolochevska/3dsrelayadmin:latest"}

docker run --rm $dockerimage -e "$psqlConnectionString" -s $secret -r $realm

echo Done
