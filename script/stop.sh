#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./stop.sh TYPE
    TYPE:   simple or zipkin or ebpf
EOS
}

if [ $# -ne 1 ]; then
    usage
    exit
fi

DOCKER_DIR=/home/tai-yu/microservices-demo/deploy/docker-compose/
DOCKER_FILE=docker-compose.yml

case "$1" in
    "simple" ) ;;
    "zipkin" ) DOCKER_FILE=docker-compose-zipkin.yml ;;
    "ebpf"   ) ;;
    * ) usage 
        exit 0 ;;
esac

docker compose -f $DOCKER_DIR$DOCKER_FILE down > /dev/null 2>&1
wait
diff --new-line-format='%L' --unchanged-line-format='' old_volume new_volume | awk '{ print "docker volume rm " $2 }' | sudo sh
wait
rm new_volume old_volume
