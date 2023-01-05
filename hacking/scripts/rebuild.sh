#!/usr/bin/env bash


pkill -f "secretd start --rpc.laddr tcp://0.0.0.0:26657"

./node_init.sh