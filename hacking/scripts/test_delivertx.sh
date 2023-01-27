#!/bin/bash
# set -x
set -e
secretd query register secret-network-params
UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ADDR=$(secretd keys show --address b)

secretd tx compute snapshot --from b "" -y --broadcast-mode sync

##This is equivalent to ./node_modules/.bin/jest -t Setup (store and instantiate contract)
#store contract
STORE_TX=$(secretd tx compute store /root/contract-simple/contract.wasm --from b -y --broadcast-mode sync --gas=5000000)
echo $STORE_TX | jq .

#instantiate contract
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
sleep 2
eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"nop\":{}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block )
echo $INIT_TX | jq .
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
sleep 2
eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="instantiate") | .attributes[] | select(.key=="contract_address") | .value ')
sleep 2

##This is equivalent to ./node_modules/.bin/jest -t QueryOld (check store value is initialized value)
eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "init val 1" ]; then
    echo "ERROR: value in store_1 $STORE_1_VALUE != \"init val 1\""
    exit 1
fi

##This is equivalent to ./node_modules/.bin/jest -t Update (update store value)
eval CODE_HASH=$(secretd q compute contract-hash $CONTRACT_ADDRESS)
CODE_HASH=${CODE_HASH:2} #strip of 0x.. from hex
secretd tx compute execute $CONTRACT_ADDRESS --generate-only "{\"store1\":{\"message\":\"hello1\"}}" --from $ADDR --enclave-key io-master-cert.der --code-hash $CODE_HASH --label $UNIQUE_LABEL  -y  --broadcast-mode sync > tx.json
secretd tx sign tx.json --chain-id secretdev-1 --from $ADDR > tx_sign.json
eval seq=$(cat tx_sign.json | jq '.auth_info.signer_infos[0].sequence')
#must increase seq number of the generated tx since delivertx call is a tx itself which increments the account sequence number
seq=$((seq+1)) 
secretd tx sign tx.json -s $seq --offline -a 1  --chain-id secretdev-1 --from $ADDR > tx_sign2.json
secretd tx compute delivertx tx_sign2.json --from $ADDR -y
sleep 2

##This is equivalent to ./node_modules/.bin/jest -t QueryNew (check store value is updated value)
eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
if [ "$STORE_1_VALUE" != "hello1" ]; then
    echo "ERROR: value in store_1 $STORE_1_VALUE != \"hello1\""
    exit 1
fi
echo "SUCCESS: value in store_1 $STORE_1_VALUE == \"hello1\""
exit 0

