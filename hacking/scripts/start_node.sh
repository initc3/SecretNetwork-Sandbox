#!/bin/bash

set -e

docker compose down

docker compose up localsecret-1 -d
sleep 5

genesis=$(docker compose exec localsecret-1 ls /genesis)
while [[ "$genesis" != *"genesis.json"* ]] 
do 
    echo "Waiting for gensis file to be generated..."
    genesis=$(docker compose exec localsecret-1 ls /genesis)
    docker compose logs localsecret-1 --tail 10   
    sleep 5
done

docker compose up localsecret-2 -d

#waiting to build secretd and start node
progs=$(docker compose exec localsecret-2 ps -ef)
while [[ "$progs" != *"secretd start --rpc.laddr tcp://0.0.0.0:26657"* ]] 
do 
    echo "Waiting for secretd build and node start..."
    progs=$(docker compose exec localsecret-2 ps -ef)
    docker compose logs localsecret-2 --tail 10   
    sleep 5
done

#waiting for blocks to start being produced before turning off localsecret-1
logs=$(docker compose logs localsecret-2 --tail 10)
while [[ "$logs" != *"executed block"* ]] 
do 
    echo "Waiting for blocks to be produced..."
    logs=$(docker compose logs localsecret-2 --tail 10)
    docker compose logs localsecret-2 --tail 10   
    sleep 5
done

docker compose logs localsecret-2 --tail 10

#./scripts/setup.sh
docker compose exec localsecret-2 ./scripts/set_init_states_toy_swap.sh
docker compose exec localsecret-2 ./scripts/setup_snip20.sh
#docker-compose exec localsecret-2 ./debug_scripts/set_init_states_simple.sh

docker compose stop localsecret-1

docker compose logs localsecret-2 --tail 5

echo "*************************************************************************"
echo "*                                                                       *"
echo "*  Secret Network Test Nodes are now setup, and ready for experiments.  *"
echo "*                                                                       *"
echo "*************************************************************************"

printf "\nNode 2 status info:\n"

docker compose exec localsecret-2 secretd status | jq .ValidatorInfo
