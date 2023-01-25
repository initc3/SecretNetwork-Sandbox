
source ./scripts/local_test_params.sh
source ./scripts/demo_utils.sh

VICTIM="secret1ldjxljw7v4vk6zhyduywh04hpj0jdwxsmrlatf"
ADV="secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq"

CONTRACT_LOC=contract-toy-swap
OBJ=contract.wasm

init_toy_swap_contract() {
  init_contract "{\"init\":{\"pool_a\":$1,\"pool_b\":$2}}"
}

set_balance() {
  execute_tx "{\"init_balance\":{\"token_type\":\"$1\",\"user\":\"$2\",\"balance\":$3}}" $ADMIN
}

prepare() {
  init_toy_swap_contract 1000 2000
  set_balance token_a $VICTIM 100
  set_balance token_b $VICTIM 100
  set_balance token_a $ADV 100
  set_balance token_b $ADV 100
}

generate_and_sign_swap() {
  generate_and_sign_tx "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}" $4 $5
}

query_pool() {
  size=$(query_contract_state "{\"$1\":{}}")
  echo $size
}

query_balance() {
  balance=$(query_contract_state "{\"balance\":{\"token_type\":\"$1\",\"user\":\"$2\"}}")
  echo "query_balance" $1 $2 $balance
}

query_balances() {
  query_balance token_a $VICTIM
  query_balance token_b $VICTIM
  query_balance token_a $ADV
  query_balance token_b $ADV
}

query_pools() {
  query_pool pool_a
  query_pool pool_b
}
