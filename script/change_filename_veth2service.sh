#!/usr/bin/env bash
set -e

usage() {
    cat <<EOS
Usage: ./change_filename_veth2service.sh RESULT_DIR
    RESULT_DIR: absolute path (/home/user/result/ebpf)
EOS
}

if [ $# -ne 1 ]; then
    usage
    exit
fi

BPF_DIR=/home/tai-yu/microservices-demo/ebpf
RESULT_DIR=$1

cd $RESULT_DIR

for f in $(ls *.log); do
	vethname=$(basename $f .log)
	service=$(grep $vethname veth_pair | awk '{print $1}')
	mv $f $service.log
done

