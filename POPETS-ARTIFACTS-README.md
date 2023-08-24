# Artifact Appendix
Paper title: **SGXonerated: Finding (and Partially Fixing) Privacy Flaws in
TEE-based Smart Contract Platforms Without Breaking the TEE**

Artifacts HotCRP Id: 87

Requested Badge: **Available**
<!-- Requested Badge: Either **Available** or **Reproducible** -->

## Description
<!-- A short description of your artifact and how it links to your paper. -->
There are two main artifacts, briefly described below.

### Artifact 1: Sandwich attacking a private swap
Contains the source code and docker-based environment to simulate a sandwich attack on
a private swap as described in section 6.2 of the paper.

### Artifact 2: Tracing attacks on SNIP-20 Transfers
Contains the source code, building toolchain and instructions to break the privacy
assumptions of receivers of SNIP-20 tokens as described in section 5.1 of the paper.


### Security/Privacy Issues and Ethical Concerns
<!--
 If your artifacts hold any risk to the security or privacy of the reviewer's machine, specify them here, e.g., if your artifacts require a specific security mechanism, like the firewall, ASLR, or another thing, to be disabled for its execution.
Also, emphasize if your artifacts contain malware samples, or something similar, to be analyzed.
In addition, you must highlight any ethical concerns regarding your artifacts here.
-->
### Artifact 1: Sandwich attacking a private swap
None.

### Artifact 2: Tracing attacks on SNIP-20 Transfers
None.

## Basic Requirements
<!--
Describe the minimal hardware and software requirements of your artifacts and estimate the compute time and storage required to run the artifacts.
-->
### Artifact 1: Sandwich attacking a private swap
We recommend using a linux machine with a recent docker engine installed.

* Time to build the docker image: ?
* Time to bootstrap the local network: ?
* Time to run the attack: ?

### Artifact 2: Tracing attacks on SNIP-20 transfers
An SGX-enabled machine is required.
See [Secret Network Node Setup](https://docs.scrt.network/secret-network-documentation/infrastructure/setting-up-a-node-validator).


### Hardware Requirements
<!--
If your artifacts require specific hardware to be executed, mention that here.
Provide instructions on how a reviewer can gain access to that hardware through remote access, buying or renting, or even emulating the hardware.
Make sure to preserve the anonymity of the reviewer at any time.
-->
#### Artifact 1: Sandwich attacking a private swap


#### Artifact 2: Tracing attacks on SNIP-20 transfers
An SGX-enabled machine is required.
See [Secret Network Node Setup](https://docs.scrt.network/secret-network-documentation/infrastructure/setting-up-a-node-validator).

### Software Requirements
<!--
Describe the OS and software packages required to evaluate your artifact.
This description is essential if you rely on proprietary software or software that might not be easily accessible for other reasons.
Describe how the reviewer can obtain and install all third-party software, data sets, and models.
-->
#### Artifact 1: Sandwich attacking a private swap
Ordinary linux machine with docker engine installed.

#### Artifact 2: Tracing attacks on SNIP-20 transfers
Ordinary linux machine with docker engine installed to build the binaries and an
SGX-enabled machine is required to run a [Secret Network Node](https://docs.scrt.network/secret-network-documentation/infrastructure/setting-up-a-node-validator).

### Estimated Time and Storage Consumption
<!--
Provide an estimated value for the time the evaluation will take and the space on the disk it will consume. 
This helps reviewers to schedule the evaluation in their time plan and to see if everything is running as intended.
More specifically, a reviewer, who knows that the evaluation might take 10 hours, does not expect an error if,  after 1 hour, the computer is still calculating things.
-->
#### Artifact 1: Sandwich attacking a private swap
#### Artifact 2: Tracing attacks on SNIP-20 transfers

## Environment
<!--
In the following, describe how to access our artifact and all related and necessary data and software components.
Afterward, describe how to set up everything and how to verify that everything is set up correctly.
-->
### Artifact 1: Sandwich attacking a private swap
### Artifact 2: Tracing attacks on SNIP-20 transfers

### Accessibility
<!--
Describe how to access your artifacts via persistent sources.
Valid hosting options are institutional and third-party digital repositories.
Do not use personal web pages.
For repositories that evolve over time (e.g., Git Repositories ), specify a specific commit-id or tag to be evaluated.
In case your repository changes during the evaluation to address the reviewer's feedback, please provide an updated link (or commit-id / tag) in a comment.
-->
#### Artifact 1: Sandwich attacking a private swap
#### Artifact 2: Tracing attacks on SNIP-20 transfers

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

#### Artifact 1: Sandwich attacking a private swap
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

##### Install Docker
Docker Engine: https://docs.docker.com/engine/install/



#### Artifact 2: Tracing attacks on SNIP-20 transfers




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


## Artifact Evaluation
<!--
This section includes all the steps required to evaluate your artifact's functionality and validate your paper's key results and claims.
Therefore, highlight your paper's main results and claims in the first subsection. And describe the experiments that support your claims in the subsection after that.
-->

### Main Results and Claims
<!--
List all your paper's main results and claims that are supported by your submitted artifacts.
-->

#### Main Result 1: Name
<!--
Describe the results in 1 to 3 sentences.
Refer to the related sections in your paper and reference the experiments that support this result/claim.
-->

#### Main Result 2: Name

### Experiments
<!--
List each experiment the reviewer has to execute. Describe:
 - How to execute it in detailed steps.
 - What the expected result is.
 - How long it takes and how much space it consumes on disk. (approximately)
 - Which claim and results does it support, and how.
-->

#### Experiment 1: Sandwich attacking a private swap
<!--
Provide a short explanation of the experiment and expected results.
Describe thoroughly the steps to perform the experiment and to collect and organize the results as expected from your paper.
Use code segments to support the reviewers, e.g.,
```bash
python experiment_1.py
```
-->
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
1) Start a validator node (node-1) and a non-validator node (node-2)

2) Store and instantiate demo contracts and set up the initial states.
The pool sizes are 1000 for `token_a` and 2000 for `token_b`.
The victim and adversary account in the toy-swap contract each have a balance
of 100 `token_a` and `token_b`.

3) Shut down node-1 to launch the attack in simulation mode without broadcasting
any transactions to the network.
</details>

Launch the sandwich attack

```shell
docker-compose exec localsecret-2 ./scripts/run_mev_demo_local.sh
```

<details>
<summary>What does the above command do?</summary>
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



#### Experiment 2: Tracing attacks on SNIP-20 transfers


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
