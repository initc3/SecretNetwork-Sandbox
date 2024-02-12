## Description of Scripts

#### start_node.sh
Setup a local network

Link: [start_node.sh](start_node.sh)

* Start a validator node (node-1) and a non-validator node (node-2)

* Calls scripts to instantiatiate Toy Smart contracts for attacks

    * For MEV attack: [`set_init_states_toy_swap.sh`](#set_init_states_toy_swapsh)

    * Snip-20 privacy attacks: [`setup_snip20`](#setup_snip20sh)

* Shut down node-1 to launch the attack in simulation mode without broadcasting any transactions to the network.


#### set_init_states_toy_swap.sh
Instantiatiate Toy Smart contracts for MEV attack
Toy Uniswap contract is at [contract-toy-swap](../contract-toy-swap/)

Link: [set_init_states_toy_swap.sh](set_init_states_toy_swap.sh)

* Initialize contract with Pool A balance 1000 and Pool B balance 2000

* Set victim and adversary accounts to have token balance to 100 for token A and token B


#### sandwich-attack.sh
Execute MEV attack against local network

Link: [sandwich-attack.sh](sandwich-attack.sh)

* Generate victim transaction that aims to swap 10 of token A for token B with slippage limit 20 (i.e. the transaction only succedes if it gets at least 20 of token B for 10 token B)

* Loops to figure out best frontrun transaction for attack:
    * Assumes at first that the best frontrun is between `low = 0` and `high = 100`
    * Set database snapshot (i.e. reset smart contract database to original state)
    * Generate a frontrun transacion with swap of `guess = (low + high)/2` of token A 
        * first frontrun transaction will try to swap 50 of token A for token B
    * Simulate the frontrun transaction 
    * Query the Pool amount for token A *before* the victim transaction
    * Simulate the victim transaction
    * Query the Pool amount for token A *after* the victim transaction
    * Calculate change in Pool amount A for before and after the victim transaction
        * If value changed the victim transaction succeded so set `low = guess`
        * If value didn't change the victim transaction failed so set `high = guess`
        * If `high == low` we found the best value for frontruning the transaction and exit loop

* Generate backrun transaction for attack that swaps the amount of token B that the attacker recieved from the frontrun transaction


#### setup_snip20.sh
Instatiate Snip 20 Smart contract for privacy attack
Snip-20 contract is at [secretSCRT](../secretSCRT/)

Link: [setup_snip20.sh](setup_snip20.sh)

* Set 2 attacker acount balance to 10000 

* Set victim sender balance to 12343

#### receiver-privacy-attack.sh
Execute privacy attack to get transfer amount for SNIP-20 transaction against local network

Link: [receiver-privacy-attack.sh](receiver-privacy-attack.sh)

* Generate a victim transaction that sends 10 from victim's account to another account

* Get the key for the victim's account balance by sending a transaction to the sender victim  and seeing which value changes in the contract database key value store

* Loops to figure out transfer amount
    * Assumes at first that the best amount is between `low = 0` and `high = 40`
    * Set the victim's account balance to 0 by deleting the value for the key holding the victim's balance we found before
    * Set database snapshot (i.e. reset smart contract database to original state)
    * Generate an adversary transaction that sends `guess = (low + high)/2` to the sender victim account
        * first transaction will send 10
    * Simulate the adversary transaction so the sender victim has a balance of `guess`
    * Simulate the victim's transaction to try and send the transfer amount
        * If the victim transaction succeded set `high = guess`
        * If the victim transaction failed set `low = guess`
        * If `high == low == guess` that is the transfer amount and exit the loop

#### balance-privacy-attack.sh
Execute privacy attack to get the SNIP-20 balance amount against local network

Link: [balance-privacy-attack.sh](balance-privacy-attack.sh)

* Get the key for the victim's account balance by sending a transaction to the sender victim  and seeing which value changes in the contract database key value store

* Loop to boost attacker's account balance to max uint_128 value
    * Generate and simulate an adversary transaction that sends the balance of *first* adversary account to *second* adversary account
        * Initially the accounts have 10000 SCRT ([see `setup_snip20.sh`](#setup_snip20sh))
    * Save the balance value from the contract database key value store for the *second* adversary account
    * Generate and simulate an adversary transaction that sends the balance of *second* adversary account to *first* adversary account
    * Set the balance of the *second* adversary account to the value before the transaction
    * repeat 114 times to get max uint_128 value in *first* adversary account

* Loop to figure out victim's balance
    * Assumes at first that the amount to send to figure out the balance is between `low = 0` and `high = max uint_128`
    * Set database snapshot (i.e. reset smart contract database to original state)
    * Generate and simulate adversary transaction to send `guess = (low + high)/2` to the victim's account
        * If the transaction succeded set `lo = guess`
        * If the transaction fails set `high = guess`
        * If `high == low == guess` then exit loop

* Balance amount is `2**128-1-guess`
