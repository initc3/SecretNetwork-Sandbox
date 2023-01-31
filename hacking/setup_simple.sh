#!/bin/bash

docker-compose exec localsecret-2 ./scripts/setup_simple.sh
docker-compose stop localsecret-1
docker-compose exec -d localsecret-2 /bin/bash -c "./scripts/backup.sh &> /root/out"
