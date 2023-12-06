# Artifact Appendix
Paper title: **SGXonerated: Finding (and Partially Fixing) Privacy Flaws in
TEE-based Smart Contract Platforms Without Breaking the TEE**

Artifacts HotCRP Id: 87

Requested Badge: **Reproducible**
<!-- Requested Badge: Either **Available** or **Reproducible** -->

## Description
<!-- A short description of your artifact and how it links to your paper. -->
There are three main artifacts, briefly described below.

### Artifact 1: Sandwich attacking a private swap
Contains the source code and docker-based environment to simulate a sandwich attack on
a private swap as described in section 6.2 of the paper.

### Artifact 2: Transfer Amount Privacy attacks on SNIP-20 Transaction
Contains the source code, building toolchain and instructions to break the transfer amount privacy
assumptions of receivers of SNIP-20 tokens as described in section 5.3 of the paper.

### Artifact 3: Account Balance Privacy attacks on SNIP-20
Contains the source code, building toolchain and instructions to break the account balance amount privacy
assumptions of SNIP-20 accounts as described in section 5.5 of the paper.

### Security/Privacy Issues and Ethical Concerns
<!--
 If your artifacts hold any risk to the security or privacy of the reviewer's machine, specify them here, e.g., if your artifacts require a specific security mechanism, like the firewall, ASLR, or another thing, to be disabled for its execution.
Also, emphasize if your artifacts contain malware samples, or something similar, to be analyzed.
In addition, you must highlight any ethical concerns regarding your artifacts here.
-->
### Artifact 1: Sandwich attacking a private swap
None.

### Artifact 2: Transfer Amount Privacy attacks on SNIP-20 Transaction
None.

### Artifact 3: Balance Privacy attacks on SNIP-20
None.

## Basic Requirements
<!--
Describe the minimal hardware and software requirements of your artifacts and estimate the compute time and storage required to run the artifacts.
-->
### Artifact 1-3
We recommend using a linux machine with a recent docker engine installed.

* Time to build the docker image: N/A we provide a prebuilt image
* Time to bootstrap the local network: < 5 minutes
* Time to run each attack for artifact 1 and 2: < 1 minute each
* Time to run attack for artifact 3: < 5 minutes

<!-- ### Artifact 4: Tracing attacks on SNIP-20 transfers
An SGX-enabled machine is required.
See [Secret Network Node Setup](https://docs.scrt.network/secret-network-documentation/infrastructure/setting-up-a-node-validator). -->


### Hardware Requirements
<!--
If your artifacts require specific hardware to be executed, mention that here.
Provide instructions on how a reviewer can gain access to that hardware through remote access, buying or renting, or even emulating the hardware.
Make sure to preserve the anonymity of the reviewer at any time.
-->
#### Artifact 1-3: 

None

<!-- #### Artifact 4: Tracing attacks on SNIP-20 transfers
An SGX-enabled machine is required.
See [Secret Network Node Setup](https://docs.scrt.network/secret-network-documentation/infrastructure/setting-up-a-node-validator). -->

### Software Requirements
<!--
Describe the OS and software packages required to evaluate your artifact.
This description is essential if you rely on proprietary software or software that might not be easily accessible for other reasons.
Describe how the reviewer can obtain and install all third-party software, data sets, and models.
-->
#### Artifact 1-3
Ordinary linux machine with docker engine installed.

<!-- #### Artifact 4: Tracing attacks on SNIP-20 transfers
Ordinary linux machine with docker engine installed to build the binaries and an
SGX-enabled machine is required to run a [Secret Network Node](https://docs.scrt.network/secret-network-documentation/infrastructure/setting-up-a-node-validator). -->

### Estimated Time and Storage Consumption
<!--
Provide an estimated value for the time the evaluation will take and the space on the disk it will consume. 
This helps reviewers to schedule the evaluation in their time plan and to see if everything is running as intended.
More specifically, a reviewer, who knows that the evaluation might take 10 hours, does not expect an error if,  after 1 hour, the computer is still calculating things.
-->
#### Artifact 1-3: Sandwich attacking a private swap

* 5 minutes setup

* <1 minute for each artifacts 1 and 2

* 5 minute artifact 3

<!-- #### Artifact 4: Tracing attacks on SNIP-20 transfers -->

<!-- * TODO time and storage consumption for secret network node?? -->

## Environment
<!--
In the following, describe how to access our artifact and all related and necessary data and software components.
Afterward, describe how to set up everything and how to verify that everything is set up correctly.
-->

### Accessibility
<!--
Describe how to access your artifacts via persistent sources.
Valid hosting options are institutional and third-party digital repositories.
Do not use personal web pages.
For repositories that evolve over time (e.g., Git Repositories ), specify a specific commit-id or tag to be evaluated.
In case your repository changes during the evaluation to address the reviewer's feedback, please provide an updated link (or commit-id / tag) in a comment.
-->
* Github commit: Latest

* Pulls prebuild images from initc3 docker image repo

### Set up the environment
<!--
Describe how the reviews should set up the environment for your artifacts, including download and install dependencies and the installation of the artifact itself.
Be as specific as possible here.
If possible, use code segments to simply the workflow, e.g.,

```bash
git clone git@my_awesome_artifact.com/repo
apt install libxxx xxx
```

Describe the expected results where it makes sense to do so.
-->

#### Artifact 
We assume a linux operating system and we have run the experiment on Ubuntu 22.04.

##### Get the code
Clone the repository, making sure you fetch the submodules, e.g.:

```shell
git clone --recurse-submodules https://github.com/initc3/SecretNetwork-Sandbox.git
```

If you are missing the submodules after having cloned, run:

```shell
git submodule update --init --recursive --remote
```


Go into the `hacking` directory:

```shell
cd hacking/
```

Setup and start the local network with:

```shell
./scripts/start_node.sh
```

<details>
<summary>What does the above command do?</summary>

[Full description of start_node.sh](./hacking/scripts/README.md#start_nodesh)

1) Start a validator node (node-1) and a non-validator node (node-2)

2) Store and instantiate Toy Uniswap demo contracts and set up the initial states for the MEV sandwhich attack.
The pool sizes are 1000 for `token_a` and 2000 for `token_b`.
The victim and adversary account in the toy-swap contract each have a balance
of 100 `token_a` and `token_b`.

3) Store and instantiate snip-20 contract and set up the initial states for the SNIP-20 privacy attack demos.
The victim account has a balance of 12343. Two attacker accounts have balance of 10000 each.

4) Shut down node-1 to launch the attack in simulation mode without broadcasting
any transactions to the network.
</details>

### Testing the Environment
<!--
Describe the basic functionality tests to check if the environment is set up correctly.
These tests could be unit tests, training an ML model on very low training data, etc.
If these tests succeed, all required software should be functioning correctly.
Include the expected output for unambiguous outputs of tests.
Use code segments to simplify the workflow, e.g.,
```bash
python envtest.py
```
-->
Check docker version:

```shell
docker version
```

Must be >= 24.0.5.

Make sure the docker compose command is available:

```shell
docker compose
```

Check that *only* node-2 is running 
```shell
docker ps | grep hacking-localsecret-2-1
```


## Artifact Evaluation
<!--
This section includes all the steps required to evaluate your artifact's functionality and validate your paper's key results and claims.
Therefore, highlight your paper's main results and claims in the first subsection. And describe the experiments that support your claims in the subsection after that.
-->

### Main Results and Claims
<!--
List all your paper's main results and claims that are supported by your submitted artifacts.
-->

#### Main Result 1: MEV attack on Uniswap contract
We are able to determine the optimal sandwhich attack transactions for a token swap contract as described in section 6.2 of the paper.  

#### Main Result 2: Transfer amount privacy attack on SNIP-20 token contract
We are able to determine the transfer amount for a SNIP-20 token transfer transaction as described in section 5.3 of the paper.  

#### Main Result 3: Account balance privacy attack on SNIP-20 token contract
We are able to determine the balance of a SNIP-20 account as described in section 5.5 of the paper.

### Experiments
<!--
List each experiment the reviewer has to execute. Describe:
 - How to execute it in detailed steps.
 - What the expected result is.
 - How long it takes and how much space it consumes on disk. (approximately)
 - Which claim and results does it support, and how.
-->

#### Experiment 1: Sandwich attacking a private swap
Launch the sandwich attack.The script creates a victim transaction swaping 10 token A for token b with slippage limit 20. (Given that the Pool balance for token a is 1000 and Pool balance for token B is 2000) It prints the optimal frontrun transaction of swaping 20 of token a for token b, and the optimal backrun transaction of swaping 40 of tokeb b for token a. 


```shell
docker compose exec localsecret-2 ./scripts/run_mev_demo_local.sh
```

<details>
<summary>What does the above command do?</summary>

[Full description of run_mev_demo_local.sh](./hacking/scripts/README.md#run_mev_demo_localsh)


The above command simulates an adversary executing the following steps:

1) Generate a victim swap transaction to swap 10 `token_a` for at least 20 `token_b`.

2) Find a front-run transaction by bisection search that, when executed before the
   victim's transaction, won't fail the victim's transaction. The front-run transaction
   found swaps 20 `token_a` with a slippage limit of 0, resulting in obtaining 40
   `token_b`.

3) After the victim's transaction, the adversary executes a back-run transaction to
   sell the 40 `token_b`, increasing their balance of `token_a` by 1 and maintaining
   their balance of `token_b`.
</details>



#### Experiment 2: Transfer amount privacy attack
Getting transfer amount. This script generates a victim transaction sending 10 of a SNIP-20 token to another account. It figures out the transfer amount prints it.

```shell
docker compose exec localsecret-2 ./scripts/test_snip20.sh
```

<details>
<summary>What does the above command do?</summary>

[Full description of test_snip20.sh](hacking/scripts/README.md#test_snip20sh)

The above command simulates an adversary executing the following steps:

1) Generate a victim transaction to transfer 10 tokens to another account

2) Find a transfer amount by bisection search to figure out the tranfer amount:
   * that sets the victim's balance to 0
   * sends an amount `guess` to the victim's account resulting in the victim's account having a balance of `guess`
   * execute the victim's transaction to see if `guess` was enough to conver the victim's transfer transaction
3) If the `guess` was enough to cover the victim's transfer transaction then `guess` is the transfer amount
</details>

#### Experiment 3: Account balance privacy attack
Getting the account balance. The script figures out and prints the victim's balance of 12343.

```shell
docker compose exec localsecret-2 ./scripts/test_balance.sh
```

<details>
<summary>What does the above command do?</summary>

[Full description of test_balance.sh](./hacking/scripts/README.md#test_balancesh)

The above command simulates an adversary executing the following steps:

1) Execute balance inflation by creating transfers between the attacker's two accounts, reseting the account balance to the original value before the transfer, and repeating this until the balance has the maximum value.

2) Find a transaction by bisection search that transfers `guess` from the attacker's account to the victim's account until it causes an overflow error.

3) The victim's balance is the `2**128-1-guess`

</details>

## Limitations
<!--
Describe which tables and results are not reproducible with the provided artifacts.
Provide an argument why this is not included/possible.
-->

## Notes on Reusability
<!--
First, this section might not apply to your artifacts.
Use it to share information on how your artifact can be used beyond your research paper, e.g., as a general framework.
The overall goal of artifact evaluation is not only to reproduce and verify your research but also to help other researchers to re-use and improve on your artifacts.
Please describe how your artifacts can be adapted to other settings, e.g., more input dimensions, other datasets, and other behavior, through replacing individual modules and functionality or running more iterations of a specific part.
-->
