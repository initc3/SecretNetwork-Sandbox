#!/bin/bash
docker-compose exec -d localsecret-2 /bin/bash -c "./scripts/rebuild.sh &> /root/out"
sleep 10
docker-compose exec localsecret-2 cat /root/out
