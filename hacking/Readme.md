
# Steps

### Update git submodules
`git submodule update --init --recursive`


### Build contracts

`make`

### Build Secret Network Node image

`./build_image.sh`

### Start Two node network

`./start_node.sh`


### Setup contracts

`./setup.sh`


### Run Demo

TODO

### Cleanup

* shutdown containers

`docker-compose down`

* delete network

`docker network rm hacking_default`
