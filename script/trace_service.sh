#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./trace_service.sh TYPE RESULT_DIR
    TYPE: simple or zipkin or ebpf
    RESULT_DIR: absolute path (/home/user/result)
EOS
}

if [ $# -ne 2 ]; then
    usage
    exit
fi

SCRIPT_DIR=/home/tai-yu/microservices-demo/script
TYPE=$1
RESULT_DIR=$2

if [ ! -d $RESULT_DIR ]; then
    mkdir -p $RESULT_DIR
fi

cd $SCRIPT_DIR
echo "docker-compose up"
./start.sh $TYPE
wait
sleep 15

if [ $TYPE = "ebpf" ]; then
    if [ ! -d $RESULT_DIR/ebpf ]; then
        mkdir $RESULT_DIR/ebpf
    else
	sudo rm $RESULT_DIR/ebpf/*
    fi
    echo "ebpf start"
    ./show_veth_pair.sh > $RESULT_DIR/ebpf/veth_pair    
    ./ebpf.sh $RESULT_DIR/ebpf
    wait
    sleep 15
fi

echo "locust start"
./locust.sh $TYPE $RESULT_DIR
wait
sleep 5
echo "locust end"

if [ $TYPE = "ebpf" ]; then
    echo "ebpf end"
    ./ebpf_stop.sh $RESULT_DIR/ebpf
    wait
    sleep 15
    ./change_filename_veth2service.sh $RESULT_DIR/ebpf
fi

echo "docker-compose down"
./stop.sh $TYPE
wait
sleep 2
