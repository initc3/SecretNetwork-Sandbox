#!/bin/bash
set -x
set -e

source ./scripts/demo_utils.sh

UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
ACC0='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
ACC1='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
ACC2='secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq'
ACC3='secret1ldjxljw7v4vk6zhyduywh04hpj0jdwxsmrlatf'
BACKUP='/root/backup_snip20'

init_balance=10000

echo "Storing contract"

STORE_TX=$(secretd tx compute store /root/secretSCRT/contract.wasm.gz --from $ACC0 -y --broadcast-mode sync --gas=5000000)
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
wait_for_tx $STORE_TX_HASH
eval CODE_ID=$($SECRETD q tx $STORE_TX_HASH | jq ".logs[].events[].attributes[] | select(.key==\"code_id\") | .value ")


echo "Instantiating contract"
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"name\":\"SSCRT\", \"symbol\":\"SSCRT\", \"decimals\": 6, \"prng_seed\": \"MDAwMA==\", \"initial_balances\":[{\"address\": \"$ACC0\", \"amount\": \"$init_balance\"},{\"address\": \"$ACC1\", \"amount\": \"$init_balance\"},{\"address\": \"$ACC2\", \"amount\": \"340282366920938463463374607431768180000\"}]}" --from $ACC0 --label $UNIQUE_LABEL  -y  --broadcast-mode sync --gas=5000000)
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
wait_for_tx $INIT_TX_HASH
eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="wasm") | .attributes[] | select(.key=="contract_address") | .value ') 

eval CODE_HASH=$(secretd q compute contract-hash $CONTRACT_ADDRESS)
CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string

echo $CONTRACT_ADDRESS > $BACKUP/contractAddress.txt
echo $CODE_HASH > $BACKUP/code.txt

