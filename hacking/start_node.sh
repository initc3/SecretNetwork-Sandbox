#!/bin/bash
set -x

docker-compose down
set -e

rm -rf secretd-1
rm -rf secretd-2


mkdir -p secretd-1
mkdir -p secretd-2
mkdir -p genesis

docker-compose up localsecret-1 -d
sleep 5
cp secretd-1/config/genesis.json genesis/genesis.json
docker-compose up localsecret-2
docker-compose up localsecret-2 -d

#waiting to build secretd and start node
progs=$(docker-compose exec localsecret-2 ps -ef)
while [[ "$progs" != *"secretd start --rpc.laddr tcp://0.0.0.0:26657"* ]] 
do 
    echo "Waiting for secretd build and node start..."
    progs=$(docker-compose exec localsecret-2 ps -ef)
    ./logs.sh    
    sleep 5

done

#waiting for blocks to start being produced before turning off localsecret-1
logs=$(docker-compose exec localsecret-2 cat /root/out )
while [[ "$logs" != *"executed block"* ]] 
do 
    echo "Waiting for blocks to be produced..."
    logs=$(docker-compose exec localsecret-2 cat /root/out )
    ./logs.sh 
    sleep 5
done

# docker-compose stop localsecret-1
./logs.sh
