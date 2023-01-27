#!/bin/bash
# set -x
set -e
secretd query register secret-network-params
UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ADDR=$(secretd keys show --address b)

echo "Stop using snapshots"
secretd tx compute snapshot --from b "" -y --broadcast-mode sync > /dev/null
sleep 3

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

##This is equivalent to ./node_modules/.bin/jest -t Update (update store value)
eval CODE_HASH=$(secretd q compute contract-hash $CONTRACT_ADDRESS)
CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string
echo "Generating Tx to update value in store to \"hello1\""
secretd tx compute execute $CONTRACT_ADDRESS --generate-only "{\"store1\":{\"message\":\"hello1\"}}" --from $ADDR --enclave-key io-master-cert.der --code-hash $CODE_HASH --label $UNIQUE_LABEL  -y  --broadcast-mode sync > tx.json
secretd tx sign tx.json --chain-id secretdev-1 --from $ADDR > tx_sign.json
eval seq=$(cat tx_sign.json | jq '.auth_info.signer_infos[0].sequence')
#must increase seq number of the generated tx since delivertx call is a tx itself which increments the account sequence number before our tx is delivered
seq=$((seq+1)) 
echo "Signing Tx"
secretd tx sign tx.json -s $seq --offline -a 1  --chain-id secretdev-1 --from $ADDR > tx_sign2.json
echo "Calling DeliverTx"
secretd tx compute delivertx tx_sign2.json --from $ADDR -y > /dev/null
sleep 2

##This is equivalent to ./node_modules/.bin/jest -t QueryNew (check store value is updated value)
eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "hello1" ]; then
    echo "ERROR: value in store_1 \"$STORE_1_VALUE\" != \"hello1\" when using snapshot1"
    exit 1
fi
echo "SUCCESS: value in store_1 \"$STORE_1_VALUE\" == \"hello1\" when using snapshot1"

echo "Stop using snapshot"
secretd tx compute snapshot --from b "" -y --broadcast-mode sync > /dev/null
sleep 2

##This is equivalent to ./node_modules/.bin/jest -t QueryOld (check store value is initialized value)
eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "init val 1" ]; then
    echo "ERROR: value in store_1 \"$STORE_1_VALUE\" != \"init val 1\"when NOT using snapshots"
    exit 1
fi
echo "SUCCESS: value in store_1 \"$STORE_1_VALUE\" == \"init val 1\" when NOT using snapshots"

exit 0

