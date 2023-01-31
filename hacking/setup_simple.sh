#!/bin/bash

set -e

docker-compose exec localsecret-2 ./scripts/set_init_states_for_demo.sh
docker-compose exec localsecret-2 ./scripts/setup_simple.sh
docker-compose stop localsecret-1