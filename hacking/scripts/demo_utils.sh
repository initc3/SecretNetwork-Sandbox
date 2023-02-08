ACC0='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
ACC1='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
ACC2='secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq'
ACC3='secret1ldjxljw7v4vk6zhyduywh04hpj0jdwxsmrlatf'
BACKUP="${SNIP20_ATTACK_DIR:-$HOME/snip20}"

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
  echo "Storing contract"
  STORE_TX=$($SECRETD tx compute store $CONTRACT_LOC/$OBJ --from $ADMIN -y --broadcast-mode sync --gas=5000000)
  eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
  wait_for_tx $STORE_TX_HASH
  eval CODE_ID=$($SECRETD q tx $STORE_TX_HASH | jq ".logs[].events[].attributes[] | select(.key==\"code_id\") | .value ")

  echo "Instantiating contract"
  INIT_TX=$($SECRETD tx compute instantiate $CODE_ID $1 --from $ADMIN --label $UNIQUE_LABEL -y --broadcast-mode sync )
  eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
  wait_for_tx $INIT_TX_HASH
  eval CONTRACT_ADDRESS=$($SECRETD q tx $INIT_TX_HASH | jq ".logs[].events[] | select(.type==\"instantiate\") | .attributes[] | select(.key==\"contract_address\") | .value ")
  echo $CONTRACT_ADDRESS > $CONTRACT_LOC/contractAddress.txt

  eval CODE_HASH=$($SECRETD q compute contract-hash $CONTRACT_ADDRESS)
  CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string
  echo $CODE_HASH > $CONTRACT_LOC/codeHash.txt
}

generate_and_sign_tx() {
  $SECRETD tx compute execute $CONTRACT_ADDRESS --generate-only $1 --from $2 --enclave-key io-master-key.txt --code-hash $CODE_HASH --label $UNIQUE_LABEL -y --broadcast-mode sync > tx_$3.json
  $SECRETD tx sign tx_$3.json --chain-id $CHAIN_ID --from $2 -y > tx_$3_sign.json
}

generate_and_sign_transfer() {
    generate_and_sign_tx "{\"transfer\":{\"recipient\":\"$2\",\"amount\":\"$3\",\"memo\":\"\"}}" $1 $4
    #$SECRETD tx compute execute $1 --generate-only "{\"transfer\":{\"recipient\":\"$4\", \"amount\": \"$5\", \"memo\":\"\"}}" --from $3 --enclave-key io-master-cert.der --code-hash $2 --label $UNIQUE_LABEL -y -broadcast-mode sync > tx_$6.json
  #$SECRETD tx sign tx_$6.json --chain-id $CHAIN_ID --from $3 -y > tx_$6_sign.json
}

simulate_tx() {
  $SECRETD tx compute simulatetx tx_$1_sign.json --from $ADMIN -y > /dev/null
}

execute_tx() {
  TX=$($SECRETD tx compute execute $CONTRACT_ADDRESS $1  --from $2 -y)
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

broadcast_tx() {
  TX=$($SECRETD tx broadcast tx_$1_sign.json --from $ADMIN -y)
  eval TX_HASH=$(echo $TX | jq .txhash )
  wait_for_tx $TX_HASH
}

query_contract_state() {
  echo $($SECRETD q compute query $CONTRACT_ADDRESS $1)
}
