#!/bin/bash
set -x
#docker-compose stop localsecret-1

docker-compose exec localsecret-2 ./scripts/test_simple.sh
# docker-compose exec localsecret-2 cp -rf /root/hist_data  /root/.secretd/data/ 
# ./rebuild_node.sh &
# docker-compose start localsecret-1
