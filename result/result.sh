#!/usr/bin/env bash

usage() {
	    cat <<EOS
Usage: ./result.sh RESULT_DIR
EOS
}

if [ $# -ne 1 ]; then
	    usage
	        exit
fi

RESULT_DIR=$1

./result.py $RESULT_DIR
wait

cd $RESULT_DIR
echo "----------ebpf-log----------"
cat ebpf/docker-compose-orders-1.log | grep orders | wc -l

for f in $(ls | grep locust-stats); do
    line=$(cat $f | grep orders)
    echo "----------${f}---------"
    echo $line | awk -F "," '{print "Req cnt\t" $3}'
    echo $line | awk -F "," '{print "Ave\t" $6}'
    echo $line | awk -F "," '{print "99%\t" $19}'
    echo $line | awk -F "," '{print "Max\t" $22}'
done

