#!/bin/bash
set -e

export SN_VERBOSE=$1

source ./scripts/log_utils.sh
source ./scripts/demo_utils.sh
source ./scripts/local_test_params.sh

init_balance=10000
victim_balance=12343

log "Storing contract"

STORE_TX=$(secretd tx compute store /root/secretSCRT/contract.wasm.gz --from $ACC0 -y --broadcast-mode sync --gas=5000000)
eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
wait_for_tx $STORE_TX_HASH
eval CODE_ID=$($SECRETD q tx $STORE_TX_HASH | jq ".logs[].events[].attributes[] | select(.key==\"code_id\") | .value ")


log "Instantiating contract"
INIT_TX=$(secretd tx compute instantiate $CODE_ID "{\"name\":\"SSCRT\", \"symbol\":\"SSCRT\", \"decimals\": 6, \"prng_seed\": \"MDAwMA==\", \"initial_balances\":[{\"address\": \"$ACC0\", \"amount\": \"$init_balance\"},{\"address\": \"$ACC1\", \"amount\": \"$init_balance\"},{\"address\": \"$ACC2\", \"amount\": \"$victim_balance\"}]}" --from $ACC0 --label $UNIQUE_LABEL  -y  --broadcast-mode sync --gas=5000000)
eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
wait_for_tx $INIT_TX_HASH
eval CONTRACT_ADDRESS=$(secretd q tx $INIT_TX_HASH | jq '.logs[].events[] | select(.type=="wasm") | .attributes[] | select(.key=="contract_address") | .value ')

eval CODE_HASH=$(secretd q compute contract-hash $CONTRACT_ADDRESS)
CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string

echo $CONTRACT_ADDRESS > $BACKUP/contractAddress.txt
echo $CODE_HASH > $BACKUP/codeHash.txt


# create viewing keys, for testing and demonstration purposes only
set_viewing_keys
