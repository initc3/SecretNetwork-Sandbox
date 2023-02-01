
# Steps

### Update git submodules
`git submodule update --init --recursive`

### Build contracts

`make`

### Build Secret Network Node image

`./build_image.sh`

### Start Two node network

`./start_node.sh`

### Setup environment for emo

`./setup_simple.sh`

### Run mev demo on local network

`docker exec -it hacking-localsecret-2-1 bash "./scripts/run_mev_demo_local.sh"`


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
