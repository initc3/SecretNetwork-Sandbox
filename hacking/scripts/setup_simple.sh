#!/bin/bash
set -x
set -e
secretd query register secret-network-params
UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ADDR=$(secretd keys show --address b)
VICTIM_ADDR=$(secretd keys show --address c)
echo "Storing contract"
STORE_TX=$(secretd tx compute store /root/contract-simple/contract.wasm --from b -y --broadcast-mode sync --gas=5000000)
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
while [ "$CODE_ID" == "" ]; do 
    echo -e "\twaiting for secred tx compute store to be included"
    sleep 2
    eval CODE_ID=$(secretd q tx $STORE_TX_HASH | jq '.logs[].events[].attributes[] | select(.key=="code_id") | .value ')
done
echo "Instantiating contract"
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"nop\":{}}" --from b --label $UNIQUE_LABEL  -y  --broadcast-mode block )
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="instantiate") | .attributes[] | select(.key=="contract_address") | .value ')
while [ "$CONTRACT_ADDRESS" == "" ]; do 
    echo -e "\t waiting for secred tx compute instatiate to be included"
    sleep 2
    eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="instantiate") | .attributes[] | select(.key=="contract_address") | .value ')
done
eval CODE_HASH=$(secretd q compute contract-hash $CONTRACT_ADDRESS)
CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string

echo "Generating Victim tx"
secretd tx compute execute $CONTRACT_ADDRESS --generate-only "{\"store1\":{\"message\":\"hello2\"}}" --from $VICTIM_ADDR --enclave-key io-master-cert.der --code-hash $CODE_HASH --label $UNIQUE_LABEL  -y  --broadcast-mode sync > tx_victim.json
echo "Signing Victim tx"
secretd tx sign tx_victim.json --chain-id secretdev-1 --from $VICTIM_ADDR > tx_victim_sign.json

cp -rf /root/.secretd/data/ /root/hist_data
echo $CONTRACT_ADDRESS > CONTRACT_ADDRESS
exit 0


