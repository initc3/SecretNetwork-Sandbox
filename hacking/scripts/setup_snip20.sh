#!/bin/bash
set -x
set -e

UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ACC1='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
ACC0='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
ACC2='secret1kzwtde98vl0rx2lgellq34sjdw0dqcx6kg5cg3'

sleep_time=2
cnt_max=5
init_balance=10000

start_secretd() {
    dev=$(secretd q account $ACC1)
    echo "$?"
}

cnt=0
while true; do
    sleep $sleep_time
    if [ $(start_secretd) != 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (pkill -f secretd); fi
    ((cnt=cnt+1))
done

sleep 5

rm -f log

cnt=0
while true; do
    sleep $sleep_time
    if [ $(start_secretd) == 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (secretd start --rpc.laddr tcp://0.0.0.0:26657 >> log 2>&1 &); fi
    ((cnt=cnt+1))
done

    sleep 5
echo "Storing contract"

STORE_TX=$(secretd tx compute store /root/secretSCRT/contract.wasm --from $ACC0 -y --broadcast-mode sync --gas=5000000)
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
while true; do 
    eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
    if [ "$CODE_ID" != "" ]; then break; fi
    sleep $sleep_time
done


echo "Instantiating contract"
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"name\":\"SSCRT\", \"symbol\":\"SSCRT\", \"decimals\": 6, \"prng_seed\": \"MDAwMA==\", \"initial_balances\":[{\"address\": \"$ACC0\", \"amount\": \"$init_balance\"},{\"address\": \"$ACC1\", \"amount\": \"$init_balance\"},{\"address\": \"$ACC2\", \"amount\": \"340282366920938463463374607431768180000\"}]}" --from $ACC0 --label $UNIQUE_LABEL  -y  --broadcast-mode block )
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
rm -rf backup
mkdir backup
cp -rf /root/.secretd/ backup
