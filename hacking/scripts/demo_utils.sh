VICTIM="secret1ldjxljw7v4vk6zhyduywh04hpj0jdwxsmrlatf"
ADV="secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq"
ADMIN="secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne"
UNIQUE_LABEL=$(date "+%Y-%m-%d-%H:%M:%S")
CONTRACT_LOC=contract-toy-swap
SECRETD=secretd
CHAIN_ID="secretdev-1"

wait_for_tx() {
  set +e
  set +x
  TX=""
  while [ "$TX" == "" ]; do
    sleep 1
    TX=$($SECRETD q tx $1)
  done
  set -e
  set -x
}

init_contract() {
  cd $CONTRACT_LOC
  make
  cd ..

  echo "Storing contract"
  STORE_TX=$($SECRETD tx compute store $CONTRACT_LOC/contract.wasm --from $ADMIN -y --broadcast-mode sync --gas=5000000)
  eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
  wait_for_tx $STORE_TX_HASH
  eval CODE_ID=$($SECRETD q tx $STORE_TX_HASH | jq ".logs[].events[].attributes[] | select(.key==\"code_id\") | .value ")

  echo "Instantiating contract"
  INIT_TX=$($SECRETD tx compute instantiate $CODE_ID "{\"init\":{\"pool_a\":$1,\"pool_b\":$2}}" --from $ADMIN --label $UNIQUE_LABEL -y --broadcast-mode sync )
  eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
  wait_for_tx $INIT_TX_HASH
  eval CONTRACT_ADDRESS=$($SECRETD q tx $INIT_TX_HASH | jq ".logs[].events[] | select(.type==\"instantiate\") | .attributes[] | select(.key==\"contract_address\") | .value ")
  echo $CONTRACT_ADDRESS > contractAddress.txt

  eval CODE_HASH=$($SECRETD q compute contract-hash $CONTRACT_ADDRESS)
  CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string
  echo $CODE_HASH > codeHash.txt
}

set_balance() {
  TX=$($SECRETD tx compute execute $CONTRACT_ADDRESS "{\"init_balance\":{\"token_type\":\"$1\",\"user\":\"$2\",\"balance\":$3}}" --from $ADMIN -y)
  eval TX_HASH=$(echo $TX | jq .txhash )
  wait_for_tx $TX_HASH
}

prepare() {
  init_contract 1000 2000
  set_balance token_a $VICTIM 100
  set_balance token_b $VICTIM 100
  set_balance token_a $ADV 100
  set_balance token_b $ADV 100
}

generate_and_sign_tx() {
  $SECRETD tx compute execute $CONTRACT_ADDRESS --generate-only "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}" --from $4 --enclave-key io-master-cert.der --code-hash $CODE_HASH --label $UNIQUE_LABEL -y --broadcast-mode sync > tx_$5.json
  $SECRETD tx sign tx_$5.json --chain-id $CHAIN_ID --from $4 -y > tx_$5_sign.json
}

simulate_tx() {
  $SECRETD tx compute simulatetx tx_$1_sign.json --from $ADMIN -y > /dev/null
}

execute_tx() {
  TX=$($SECRETD tx compute execute $CONTRACT_ADDRESS "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}"  --from $4 -y)
  eval TX_HASH=$(echo $TX | jq .txhash )
  wait_for_tx $TX_HASH
}

set_snapshot() {
  $SECRETD tx compute snapshot --from $ADMIN "snapshot$1" -y --broadcast-mode sync > /dev/null
  echo "set_snapshot to snapshot$1"
}

reset_snapshot() {
  $SECRETD tx compute snapshot --from $ADMIN "" -y --broadcast-mode sync
  echo "reset_snapshot to default dbstore"
}

query_pool() {
  size=$($SECRETD q compute query $CONTRACT_ADDRESS "{\"$1\":{}}")
  echo $size
}

broadcast_tx() {
  TX=$($SECRETD tx broadcast tx_$1_sign.json --from $ADMIN -y)
  eval TX_HASH=$(echo $TX | jq .txhash )
  wait_for_tx $TX_HASH
}

query_balance() {
  balance=$($SECRETD q compute query $CONTRACT_ADDRESS "{\"balance\":{\"token_type\":\"$1\",\"user\":\"$2\"}}")
  echo "query_balance" $1 $2 $balance
}

query_balances() {
  query_balance token_a $VICTIM
  query_balance token_b $VICTIM
  query_balance token_a $ADV
  query_balance token_b $ADV
}