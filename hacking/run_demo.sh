#!/bin/bash
sudo ./start_node.sh

./setup_simple.sh

docker-compose exec localsecret-2 ./scripts/run_mev_demo_local.sh