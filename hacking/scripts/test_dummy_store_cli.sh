#!/bin/bash
set -x
set -e

UNIQUE_LABEL="12345678"

secretd tx compute snapshot --from b "" -y --broadcast-mode sync

#This is equivalent to ./node_modules/.bin/jest -t Setup

#store contract
STORE_TX=$(secretd tx compute store /root/contract-simple/contract.wasm --from b -y --broadcast-mode block --gas=5000000)
echo $STORE_TX | jq .
tx_height=$(echo $STORE_TX | jq .height)
while ["$tx_height" == "0"] do 
    STORE_TX=$(secretd tx compute store /root/contract-simple/contract.wasm --from b -y --broadcast-mode block --gas=5000000)
    tx_height=$(echo $STORE_TX | jq .height)
    sleep 5
done

#instantiate contract
echo $STORE_TX | jq .
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"nop\":{}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block )
echo $INIT_TX | jq .
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="instantiate") | .attributes[] | select(.key=="contract_address") | .value ')

#This is equivalent to ./node_modules/.bin/jest -t QueryOld
STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ $STORE_1_VALUE -ne "init val 1" ]; then
    echo "value in store_1 $STORE_1_VALUE != \"init val 1\""
    exit 1
fi

secretd tx compute snapshot --from b "snapshot1" -y

#This is equivalent to ./node_modules/.bin/jest -t Update
secretd tx compute execute $CONTRACT_ADDRESS "{\"store1\":{\"message\":\"hello1\"}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block
#This is equivalent to ./node_modules/.bin/jest -t QueryNew
STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ $STORE_1_VALUE -ne "hello1"];
    echo "value in store_1 $STORE_1_VALUE != \"hello1\""
    exit 1
fi

secretd tx compute snapshot --from b "" -y

#This is equivalent to ./node_modules/.bin/jest -t QueryOld
STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ $STORE_1_VALUE -ne "init val 1" ]; then
    echo "value in store_1 $STORE_1_VALUE != \"init val 1\""
    exit 1
fi

secretd tx compute snapshot --from b "snapshot1" -y

#This is equivalent to ./node_modules/.bin/jest -t Update
secretd tx compute execute $CONTRACT_ADDRESS "{\"store1\":{\"message\":\"hello1\"}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block

#This is equivalent to ./node_modules/.bin/jest -t QueryNew
STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ $STORE_1_VALUE -ne "hello1"];
    echo "value in store_1 $STORE_1_VALUE != \"hello1\""
    exit 1
fi