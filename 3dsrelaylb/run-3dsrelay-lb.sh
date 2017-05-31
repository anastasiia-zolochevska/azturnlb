#!/bin/sh

# Error if non-true result
set -e

if [ -z "$1" ]; then
    echo "Usage: 3dsrelaylb <IP:PORT_OF_RELAY_SERVER> [<IP:PORT_OF_ANOTHER_RELAY_SERVER> ...]"
    exit 1
fi

alternateServerParams=""

for i in "$@";
do
    alternateServerParams=" $alternateServerParams --alternate-server $i"
done

echo $alternateServerParams

# Error on unset variables
set -u

#echo Discovering internal and external ip address...
#internalIp="$(ip a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
#externalIp="$(dig +short myip.opendns.com @resolver1.opendns.com)"
#echo External ip address: $externalIp
#echo Internal ip address: $internalIp

echo Starting turnserver
exec turnserver -v \
    $alternateServerParams \
    -n \
    -p 3478 \
    --lt-cred-mech \
    --no-dtls \
    --no-tls \
