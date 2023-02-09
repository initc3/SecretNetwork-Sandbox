#!/bin/bash

set -e
set -x

docker compose down
docker compose up -d

# waiting for blocks to start being produced before turning off localsecret-1
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

docker compose logs localsecret-2 --follow
