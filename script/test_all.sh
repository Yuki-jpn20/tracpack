#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./test_all.sh RESULT_DIR
    RESULT_DIR: absolute path (/home/user/result)
EOS
}

if [ $# -ne 1 ]; then
    usage
    exit
fi

SCRIPT_DIR=/home/tai-yu/microservices-demo/script
RESULT_DIR=$1

if [ ! -d $RESULT_DIR ]; then
    mkdir -p $RESULT_DIR
fi

cd $SCRIPT_DIR
./trace_service.sh simple $RESULT_DIR
wait
./trace_service.sh ebpf $RESULT_DIR
wait
./trace_service.sh zipkin $RESULT_DIR
wait
