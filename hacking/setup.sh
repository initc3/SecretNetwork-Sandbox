#!/bin/bash
set -x

docker-compose exec localsecret-2 ./scripts/set_init_states_for_demo.sh
docker-compose exec localsecret-2 ./scripts/setup_simple.sh
docker-compose exec localsecret-2 ./scripts/setup_snip20.sh
docker-compose stop localsecret-1
