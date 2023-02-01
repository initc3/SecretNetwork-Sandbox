#!/bin/bash

set -e
set -x

# fetch third_party/incubator-teaclave-sgx-sdk & cosmos-sdk
git submodule update --init --recursive --remote

./build_image.sh

# start a validator node (node-1) and a non-validator node (node-2)
./start_node.sh

# set up initial states for our demo
# shut down the validator node (node-1)
# take snapshot of the current states (used in rewinding attack later)
./setup_simple.sh

# run the mev demo
docker-compose exec localsecret-2 ./scripts/run_mev_demo_local.sh
