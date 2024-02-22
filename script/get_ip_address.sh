i=1
docker ps --format '{{.Names}}' | 
while read line
    do 
        echo -n "${line} & "
        echo -n "docker inspect --format '{{ \$network := index .NetworkSettings.Networks \"docker-compose_default\" }}{{ \$network.IPAddress }}' ${line}" | sudo sh
        i=$(expr $i + 1)
done
