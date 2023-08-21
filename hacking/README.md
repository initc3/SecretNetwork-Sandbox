# Running the MEV Demo

### Update Git Submodules
Fetch the git submodules by running the following command:

```shell
git submodule update --init --recursive --remote
```

### Requirements
Docker Engine: https://docs.docker.com/engine/install/

### Build Secret Network Node Image
Run all the command below under directory `hacking`.

The demo contracts are built when building the image. Run the following
command to build the image:

```shell
docker compose build
```

### Setup Environment

```shell
./scripts/start_node.sh
```

The above command will:

1) Start a validator node (node-1) and a non-validator node (node-2)

2) Store and instantiate demo contracts and set up the initial states. 
The pool sizes are 1000 for `token_a` and 2000 for `token_b`. 
The victim and adversary account in the toy-swap contract each have a balance
of 100 `token_a` and `token_b`.

3) Shut down node-1 to launch the attack in simulation mode without broadcasting
any transactions to the network.


### Launch MEV Attack
```shell
docker-compose exec localsecret-2 ./scripts/run_mev_demo_local.shi
```

The above command simulates an adversary executing the following steps:

1) Generate a victim swap transaction to swap 10 `token_a` for at least 20 `token_b`.

2) Find a front-run transaction by bisection search that, when executed before the
   victim's transaction, won't fail the victim's transaction. The front-run transaction
   found swaps 20 `token_a` with a slippage limit of 0, resulting in obtaining 40
   `token_b`.

3) After the victim's transaction, the adversary executes a back-run transaction to
   sell the 40 `token_b`, increasing their balance of `token_a` by 1 and maintaining
   their balance of `token_b`.


### Cleanup

TODO


[//]: # ()
[//]: # (### Rebuild )

[//]: # ()
[//]: # (Rebuild `go-cosmwasm/src` and `x/` and restart node &#40;after `./start_node.sh` was run&#41;)

[//]: # ()
[//]: # (* From outside docker container)

[//]: # ()
[//]: # (`./rebuild_node.sh`)

[//]: # ()
[//]: # (* From inside docker container)

[//]: # ()
[//]: # (```bash)

[//]: # (docker-compose exec localsecret-2 bash)

[//]: # ($ ./scripts/rebuild.sh &> /root/out &)

[//]: # ($ cat out)

[//]: # (```)

[//]: # ()
[//]: # (* shutdown containers)

[//]: # ()
[//]: # (`docker-compose down`)

[//]: # ()
[//]: # (* delete network)

[//]: # ()
[//]: # (`docker network rm hacking_default`)

[//]: # ()
[//]: # (### Other)

[//]: # (#### Update protobuf for rpc calls)

[//]: # ()
[//]: # (* Update proto spec and other relevant files)

[//]: # ()
[//]: # (    * [msg.proto]&#40;../proto/secret/compute/v1beta1/msg.proto&#41;)

[//]: # (    * [alias.go]&#40;../x/compute/alias.go&#41;)

[//]: # (    * [cli/tx.go]&#40;x/compute/client/cli/tx.go&#41;)
[//]: # (    * [rest/tx.go]&#40;x/compute/client/rest/tx.go&#41;)

[//]: # (    * [handler.go]&#40;x/compute/handler.go&#41;)

[//]: # (    * [msg_server.go]&#40;x/compute/internal/keeper/msg_server.go&#41;)

[//]: # (    * [codec.go]&#40;x/compute/internal/types/codec.go&#41;)

[//]: # (    * [msg.go]&#40;x/compute/internal/types/msg.go&#41;)

[//]: # ()
[//]: # (* generate protobuf files `make proto-gen`)

[//]: # ()
[//]: # (    * you can ignore errors: `W0123 19:43:24.908481     375 services.go:38] No HttpRule found for method: Msg....` )

[//]: # ()
[//]: # (* build image `./build_image.sh` or `./rebuild_node.sh`)

[//]: # ()
[//]: # (#### Keeper)

[//]: # ([keeper.go]&#40;../x/compute/internal/keeper/keeper.go#L478&#41;)
