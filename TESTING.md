# Testing
Quick help and reminder on how to run unit and integration tests.

## Prerequisites
* [node v16+](https://nodejs.org)
* [rust](https://www.rust-lang.org/tools/install)
* [docker engine](https://docs.docker.com/engine/install/ubuntu/)
* [docker compose](https://docs.docker.com/compose/install/linux/#install-using-the-repository)

> **Note**: [Docker BuildKit][buildkit] must be enablad to build the
localsecret docker image. Docker BuildKit can be enabled in various ways,
e.g.:
>
> * setting the environment variable `DOCKER_buildkit=1` ([docs][buildkit])
> * setting the daemon configuration in `/etc/docker/daemon.json` ([docs][buildkit])
> * setting buildx as the default builder by running `docker buildx install` ([docs][buildx])

### Note about submodules
The SecretNetwork repository has submodules which must be initialized. This
can be done when cloning the repository, e.g.:

```console
git clone --recurse-submodules https://github.com/scrtlabs/SecretNetwork.git
```

If you already have the clone but not the submodule, run the following
command:

```console
git submodule update --init --recursive
```

## Enclave Unit Tests
There's a `Dockerfile` to build and run the enclave tests under
[`deployment/dockerfiles/enclave-test.Dockerfile`][deployment/dockerfiles/enclave-test.Dockerfile].

There's a `make` target to simplify building the image:

```console
make docker_enclave_test
```

Note that by default the image is built for hardware mode (`SGX_MODe=HW`),
meaning that an SGX enable machine is necessary. To build in simulation
(software) mode, set `SGX_MODE=SW`, e.g.:


```console
SGX_MODE=SW make docker_enclave_test
```

To run the tests:

```console
docker run --rm -it rust-enclave-test
```

If you wish to work in a container, override the entrypoint , e.g.:

```console
docker run --rm -it --entrypoint='' rust-enclave-test bash
```

Once in the container, the tests can be run with `make`:

```console
make enclave-tests
```

If you wish to make modifications to the code, then you'll probably want to
mount the relevant source code, e.g.:

```console
docker run --rm -it --entrypoint='' \
    --volume $PWD/cosmwasm/enclaves/execute/src/:/enclave-test/cosmwasm/enclaves/execute/src/ \
    rust-enclave-test bash
```

### Using docker compose
By default `SGX_MODE=SW`, i.e. simulation mode, i.e. SGX chip not required.

Run the enclave unit tests in simulation mode:

```console
docker compose --file deployment/dockerfiles/test.yml up
```

To build and run in hardware mode:

```console
docker compose --file deployment/dockerfiles/test.yml build --build-arg SGX_MODE=HW
```


## Integrations Tests

### Launch a localsecret network

```console
docker compose --file deployment/dockerfiles/ibc/dev.yml up
```

### Run the integration tests

```console
cd integration-tests
```

Install dependencies with `yarn`:

```console
yarn
```

Run the tests:

```console
yarn test
```

### Making modifications to the code
See the `volumes` field in the `dev.yml` compose file to mount specifc source code,
which can be available in a container used to re-build specific components.

As time progresses, the development workflow will be improved.

### Tips
The first time the `docker compose up` command is run the images will
also be built. Afterwards, to trigger a re-build of the images, you can run:

```console
docker compose --file deployment/dockerfiles/ibc/dev.yml up --build
```

This will still use cached layers, so if you wish to re-build the images without using
the cached layers, you can use the `build` subcommand:

```console
docker compose --file deployment/dockerfiles/ibc/dev.yml up build --no-cache
```

[buildkit]: https://docs.docker.com/build/buildkit/#getting-started
[buildx]: https://docs.docker.com/build/buildx/install/#set-buildx-as-the-default-builder
