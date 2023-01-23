#!/bin/bash
set +x
set -e

./node_modules/.bin/jest -t Setup
./node_modules/.bin/jest -t QueryOld


docker-compose exec localsecret-2 secretd tx compute snapshot --from b "snapshot1" -y
./logs.sh | grep snapshot
./logs.sh | grep "&k"

# docker-compose restart localsecret-2
# sleep 10

./node_modules/.bin/jest -t Update

docker-compose exec localsecret-2 secretd tx compute snapshot --from b "" -y
./logs.sh | grep snapshot

# docker-compose restart localsecret-2
# sleep 10

./node_modules/.bin/jest -t QueryOld


docker-compose exec localsecret-2 secretd tx compute snapshot --from b "snapshot1" -y
./logs.sh | grep snapshot
# docker-compose restart localsecret-2
# sleep 10

./node_modules/.bin/jest -t Update
./node_modules/.bin/jest -t QueryNew