#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./trace_service.sh TYPE
    TYPE:   simple or zipkin or ebpf
EOS
}

if [ $# -ne 1 ]; then
    usage
    exit
fi

DOCKER_DIR=/home/tai-yu/microservices-demo/deploy/docker-compose
DOCKER_FILE=docker-compose.yml

case "$1" in
    "simple" ) ;;
    "zipkin" ) DOCKER_FILE=docker-compose-zipkin.yml ;;
    "ebpf"   ) ;;
    * ) usage 
        exit 0 ;;
esac

docker volume ls > old_volume
wait
docker compose -f $DOCKER_DIR/$DOCKER_FILE up -d > /dev/null 2>&1
wait
sleep 5
docker volume ls > new_volume
