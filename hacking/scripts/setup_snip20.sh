#!/bin/bash
set -x
set -e

UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ACC1='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
ACC0='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
ACC2='secret1kzwtde98vl0rx2lgellq34sjdw0dqcx6kg5cg3'

sleep_time=2
cnt_max=5

start_secretd() {
    dev=$(secretd q account $ACC1)
    echo "$?"
}


secretd start >> log 2>&1 &

cnt=0
while true; do
    ((cnt=cnt+1))
    sleep $sleep_time
    if [ $(start_secretd) == 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (secretd start >> log 2>&1 &); fi
done

    sleep $sleep_time
echo "Storing contract"
STORE_TX=$(secretd tx compute store /root/secretSCRT/contract.wasm --from $ACC0 -y --broadcast-mode sync --gas=5000000)
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
while [ "$CODE_ID" == "" ]; do 
    echo -e "\twaiting for secred tx compute store to be included"
    sleep 2
    eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
done


echo "Instantiating contract"
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"name\":\"SSCRT\", \"symbol\":\"SSCRT\", \"decimals\": 6, \"prng_seed\": \"MDAwMA==\", \"initial_balances\":[{\"address\": \"$ACC0\", \"amount\": \"10000\"},{\"address\": \"$ACC1\", \"amount\": \"10000\"},{\"address\": \"$ACC2\", \"amount\": \"340282366920938463463374607431768180000\"}]}" --from $ACC0 --label $UNIQUE_LABEL  -y  --broadcast-mode block )
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )

eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="wasm") | .attributes[] | select(.key=="contract_address") | .value ') 

while [ "$CONTRACT_ADDRESS" == "" ]; do
    echo -e "waiting for secred tx compute instatiate to be included"
    sleep 2
    eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="wasm") | .attributes[] | select(.key=="contract_address") | .value ')
done
echo $CONTRACT_ADDRESS > contractAddress.txt

eval CODE_HASH=$(secretd q compute contract-hash $CONTRACT_ADDRESS)
CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string
echo $CODE_HASH > code.txt

pkill -f secretd

cnt=0
while true; do
    ((cnt=cnt+1))
    sleep $sleep_time
    if [ $(start_secretd) != 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (pkill -f secretd); fi
done

sleep 5
cp -rf /root/.secretd/* backup/
