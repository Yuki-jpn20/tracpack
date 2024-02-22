#!/usr/bin/env bash

usage() {
    cat <<EOS
Usage: ./ebpf.sh RESULT_DIR
    RESULT_DIR: absolute path (/home/user/result/ebpf)
EOS
}

if [ $# -ne 1 ]; then
    usage
    exit
fi

BPF_DIR=/home/tai-yu/microservices-demo/ebpf
RESULT_DIR=$1

cd $BPF_DIR

# all service
# cat $1/veth_pair | grep -v db | grep -v edge | grep -v rabbit | grep -v queue | grep -v sim | awk '{ print "python3 ./update_len.py " $2 " &" }' | sudo sh
# TRACE_NIC=$(cat $1/veth_pair | grep -v db | grep -v edge | grep -v rabbit | grep -v queue | grep -v sim | awk '{ print $2 }')
# for nic in $TRACE_NIC; do
#     echo "python3 ./store_metrics.py ${nic} > ${RESULT_DIR}/${nic}.log &" | sudo sh
# done

# only orders
cat $1/veth_pair | grep orders | grep -v db | awk '{ print "python3 ./update_len.py " $2 " &" }' | sudo sh
TRACE_NIC=$(cat $1/veth_pair | grep orders | grep -v db | awk '{ print $2 }')
for nic in $TRACE_NIC; do
    echo "python3 ./store_metrics.py ${nic} > ${RESULT_DIR}/${nic}.log &" | sudo sh
done
