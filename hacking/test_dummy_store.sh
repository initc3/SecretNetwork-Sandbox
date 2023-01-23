#!/bin/bash
set +x
set -e
docker-compose exec localsecret-2 secretd tx compute snapshot --from b "" -y
# ./logs.sh | grep snapshot

./node_modules/.bin/jest -t Setup
./node_modules/.bin/jest -t QueryOld

docker-compose exec localsecret-2 secretd tx compute snapshot --from b "snapshot1" -y
# ./logs.sh | grep snapshot

./node_modules/.bin/jest -t Update

docker-compose exec localsecret-2 secretd tx compute snapshot --from b "" -y
# ./logs.sh | grep snapshot

./node_modules/.bin/jest -t QueryOld


docker-compose exec localsecret-2 secretd tx compute snapshot --from b "snapshot1" -y
# ./logs.sh | grep snapshot

./node_modules/.bin/jest -t QueryNew