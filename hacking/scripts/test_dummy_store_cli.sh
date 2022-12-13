#!/bin/bash
# set -x
set -e
UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ADDR=$(secretd keys show --address b)

echo "Stop using snapshots"
secretd tx compute snapshot --from b "" -y --broadcast-mode sync > /dev/null
sleep 2

##This is equivalent to ./node_modules/.bin/jest -t Setup (store and instantiate contract)
##store contract
echo "Storing contract"
STORE_TX=$(secretd tx compute store /root/contract-simple/contract.wasm --from b -y --broadcast-mode sync --gas=5000000)
eval tx_height=$(echo $STORE_TX | jq .height)
while [ "$tx_height" == "0" ]; do 
    # echo "STORE_TX:"
    # echo $STORE_TX | jq .
    echo -e "\tretry secred tx compute store"
    sleep 2
    STORE_TX=$(secretd tx compute store /root/contract-simple/contract.wasm --from b -y --broadcast-mode block --gas=5000000)
    eval tx_height=$(echo $STORE_TX | jq .height)
done
# echo $STORE_TX | jq .
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')

##instantiate contract
echo "Instantiating contract"
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"nop\":{}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block )
eval tx_height=$(echo $INIT_TX | jq .height)
while [ "$tx_height" == "0" ]; do
    # echo "INIT_TX:"
    # echo $INIT_TX | jq .
    echo -e "\tretry secred tx compute instantiate"
    sleep 2
    INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"nop\":{}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block )
    eval tx_height=$(echo $INIT_TX | jq .height)
done
# echo $INIT_TX | jq .
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="instantiate") | .attributes[] | select(.key=="contract_address") | .value ')

##This is equivalent to ./node_modules/.bin/jest -t QueryOld (check store value is initialized value)
eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "init val 1" ]; then
    echo "ERROR: value in store1 $STORE_1_VALUE != \"init val 1\""
    exit 1
fi
echo "Contract initiated with \"$STORE_1_VALUE\" in store1"

echo "Using snapshot1"
secretd tx compute snapshot --from b "snapshot1" -y --broadcast-mode sync > /dev/null
sleep 2

echo "Updating value in store to \"hello1\""
UPDATE_TX=$(secretd tx compute execute $CONTRACT_ADDRESS "{\"store1\":{\"message\":\"hello1\"}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block)
eval tx_code=$(echo $UPDATE_TX | jq .code)
if [ "$tx_code" != "0" ]; then
    echo "UPDATE_TX:"
    echo $UPDATE_TX | jq . 
    echo "ERROR: calling secretd tx compute execute"
    exit 1   
fi 

echo "Stop using snapshots"
secretd tx compute snapshot --from b "" -y --broadcast-mode sync > /dev/null
sleep 2

##This is equivalent to ./node_modules/.bin/jest -t QueryOld (check store value is initialized value)
eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "init val 1" ]; then
    echo "ERROR: value in store_1 \"$STORE_1_VALUE\" != \"init val 1\" when NOT using snapshots"
    exit 1
fi
echo "SUCCESS: value in store_1 \"$STORE_1_VALUE\" == \"init val 1\" when NOT using snapshots"


echo "Using snapshot1"
secretd tx compute snapshot --from b "snapshot1" -y --broadcast-mode sync > /dev/null
sleep 2

eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "hello1" ]; then
    echo "ERROR: value in store1 \"$STORE_1_VALUE\" != \"hello1\" when using snapshot1"
    exit 1
fi
echo "SUCCESS: value in store_1 \"$STORE_1_VALUE\" == \"hello1\" when using snapshot1"