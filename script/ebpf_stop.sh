#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./ebpf_stop.sh RESULT_DIR
    RESULT_DIR: absolute path (/home/user/result/ebpf)
EOS
}

if [ $# -ne 1 ]; then
    usage
    exit
fi

RESULT_DIR=$1

ps aux | grep update_len | awk '{ print "kill " $2 }' | sudo sh
ps aux | grep store_metrics | awk '{ print "kill " $2 }' | sudo sh

find ${RESULT_DIR} -type f -size 0 -exec sudo rm {} \;

