#!/bin/bash
set +x

docker-compose down
set -e

rm -rf secretd-1
rm -rf secretd-2


mkdir -p secretd-1
mkdir -p secretd-2
mkdir -p secretd-2-state
mkdir -p genesis

docker-compose up localsecret-1 -d
sleep 5
cp secretd-1/config/genesis.json genesis/genesis.json
docker-compose up localsecret-2
docker-compose up localsecret-2 -d
sleep 20
docker-compose stop localsecret-1
sleep 10
./logs.sh