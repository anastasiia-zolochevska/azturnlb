#!/bin/bash

set -u

STATUS=2
SLEEP=7

while [ $STATUS -gt 0 ]
do
    echo "Waiting for docker to be ready...."
    sleep $SLEEP
    DOCKER_PS_OUTPUT=`docker ps`
    STATUS=$?
    echo $DOCKER_PS_OUTPUT
done

echo "Docker ready."
STATUS=22
MAX_RETRY=3
RETRY=0
while [ $STATUS -gt 0 ] && [ $RETRY -lt $MAX_RETRY ]
do
    sleep $SLEEP
    echo "Executing docker $@"
    DOCKER_OUTPUT=`docker $@`
    STATUS=$?
    echo $DOCKER_OUTPUT
    RETRY=$(($RETRY + 1)) 
done

exit $STATUS
