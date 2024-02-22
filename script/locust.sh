#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./locust.sh TYPE RESULT_DIR
    TYPE:   simple or zipkin or ebpf
    RESULT_DIR: absolute path (/home/user/result)
EOS
}

if [ $# -ne 2 ]; then
    usage
    exit
fi

LOCUST_DIR=/home/tai-yu/microservices-demo/load-test
RESULT_DIR=$2

case "$1" in
    "simple" ) FILE=simple ;;
    "zipkin" ) FILE=zipkin ;;
    "ebpf"   ) FILE=bpf ;;
    * ) usage 
        exit 0 ;;
esac

cd $LOCUST_DIR
locust --config locust.conf > $RESULT_DIR/$FILE-all-req-log 2> /dev/null
wait
./history.py > $RESULT_DIR/$FILE-response-time
rm tmp
wait
mv locust_stats.csv $RESULT_DIR/$FILE-locust-stats
