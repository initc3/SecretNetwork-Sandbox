set -e
set -x

USER=secret15vya8x6l5qcf0xw28xwehjxd9stymtvf4sqr6q
PASSPHRASE=password
SECRETD=./secretd
sSCRT_ADDR=secret18vd8fpwxzck93qlwghaj6arh4p7c5n8978vsyg
SHD_ADDR=secret19ymc8uq799zf36wjsgu4t0pk8euddxtx5fggn8
exchange_addr=secret1pak8feexy97myp22pjkxmsp5p8dmlkp4mkfxsl

wait_for_tx() {
  eval TX_HASH=$(echo $1 | jq .txhash )

  set +e
  set +x
  TX=""
  while [ "$TX" == "" ]; do
    sleep 1
    TX=$($SECRETD q tx $TX_HASH)
  done
  set -e
  set -x
}

deposit_sSCRT() {
  TX=$(echo $PASSPHRASE | $SECRETD tx compute execute $sSCRT_ADDR "{\"deposit\": {}}" --from $USER --amount=$1 -y)
  wait_for_tx $TX
}

query_snip_20_balance() {
  viewing_key=vk
  TX=$(echo $PASSPHRASE | $SECRETD tx compute execute $1 "{\"set_viewing_key\": {\"key\":\"$viewing_key\"}}" --from $2 -y)
  wait_for_tx $TX
  echo $PASSPHRASE | $SECRETD q compute query $1 "{\"balance\": {\"key\":\"$viewing_key\",\"address\":\"$2\"}}"
}

swap_sSCRT_to_SHD() {
  msg=$(echo -n "{\"swap\":{\"to\":\"$2\",\"expected_return\":\"$3\"}}" | base64 -w0)
  TX=$(echo $PASSPHRASE | $SECRETD tx compute execute $sSCRT_ADDR "{\"send\": {\"amount\":\"$1\",\"recipient\":\"$exchange_addr\",\"msg\":\"$msg\"}}" --gas 3000000 --from $USER --keyring-backend file -y)
  wait_for_tx $TX
}

query_pool() {
  pool=$(echo $PASSPHRASE | $SECRETD q compute query $exchange_addr "{\"pair_info\": {}}")
  echo $pool
}

# turn SCRT to sSCRT
deposit_sSCRT amt=1000000uscrt

query_snip_20_balance $sSCRT_ADDR $USER
query_snip_20_balance $SHD_ADDR $USER

swap_sSCRT_to_SHD 100000 $USER 0

query_snip_20_balance $sSCRT_ADDR $USER
query_snip_20_balance $SHD_ADDR $USER

query_pool