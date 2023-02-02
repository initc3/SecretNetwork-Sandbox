#!/bin/bash

set -e
set -x

SECRETD=secretd
ADMIN='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'

start_secretd() {
    dev=$($SECRETD q account $ADMIN)
    echo "$?"
}

query_tx_res() {
    dev=$($SECRETD q tx $1)
    echo "$?"
}

pkill -f "$SECRET start --rpc.laddr tcp://0.0.0.0:26657"
sleep_time=3
cnt=0
cnt_max=5
while true; do
    ((cnt=cnt+1))
    sleep $sleep_time
    if [ $(start_secretd) != 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (pkill -f $SECRETD); fi
done

mkdir -p /root/hist_data
cp -r /root/.secretd/ /root/hist_data

RUST_BACKTRACE=1 $SECRET start --rpc.laddr "tcp://0.0.0.0:26657" &
disown
