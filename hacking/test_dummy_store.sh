#!/bin/bash
set +x
set -e


./node_modules/.bin/jest -t Setup
./node_modules/.bin/jest -t QueryOld

docker-compose exec localsecret-2 /bin/bash -c "export DUMMY_STORE=true"

./node_modules/.bin/jest -t Update
./node_modules/.bin/jest -t QueryOld

docker-compose stop localsecret-2
docker-compose start localsecret-2

docker-compose exec localsecret-2 /bin/bash -c "export DUMMY_STORE=false"

./node_modules/.bin/jest -t Update
./node_modules/.bin/jest -t QueryNew