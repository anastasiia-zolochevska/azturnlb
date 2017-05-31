#!/bin/bash

# Error if non-true result
set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: 3dsrelay <postgres_connection_string> <default_realm>"
    exit 1
fi

# Error on unset variables
set -u

echo Discovering internal and external ip address...
internalIp="$(ip a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
externalIp="$(dig +short myip.opendns.com @resolver1.opendns.com)"
echo External ip address: $externalIp
echo Internal ip address: $internalIp

echo Starting turnserver
exec turnserver -v \
    -n \
    -L "$internalIp" \
    -E "$internalIp" \
    -X "$externalIp" \
    -p 3478 \
    --lt-cred-mech \
    --no-dtls \
    --no-tls \
    --psql-userdb "$1" \
    --realm $2
