#!/bin/bash
set +x

./start_node.sh

./node_modules/.bin/jest -t Setup
./node_modules/.bin/jest -t QueryOld

cp -r secretd-2/* secretd-2-state/

./node_modules/.bin/jest -t Update
./node_modules/.bin/jest -t QueryNew

docker-compose stop localsecret-2
docker-compose start localsecret-2

sudo cp -r secretd-2-state/* secretd-2/* 

./node_modules/.bin/jest -t QueryOld
docker-compose down