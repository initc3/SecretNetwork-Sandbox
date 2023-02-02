#!/bin/bash
set -x
# docker-compose start localsecret-1 
docker-compose exec -d localsecret-2 /bin/bash -c "./scripts/rebuild2.sh"
sleep 5

#waiting to build secretd and start
progs=$(docker-compose exec localsecret-2 ps -ef)
while [[ "$progs" != *"secretd start --rpc.laddr tcp://0.0.0.0:26657"* ]] 
do 
    progs=$(docker-compose exec localsecret-2 ps -ef)
    echo "Waiting for secretd build and node start..."
    sleep 5
done

# logs=$(docker-compose exec localsecret-2 cat /root/out )
# while [[ "$logs" != *"finalizing commit of block"* ]] 
# do 
#     logs=$(docker-compose exec localsecret-2 cat /root/out )
#     ./logs.sh
#     echo "Waiting for blocks to be produced..."
#     sleep 5
# done
docker-compose logs localsecret-2 --tail 10
