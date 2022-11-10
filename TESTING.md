# Testing
Quick help and reminder on how to run integration tests.

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

## Build the localsecret image
Run

```console
DOCKER_TAG=v0.0.0 make localsecret
```

> **Note**: If you are relying on the `DOCKER_BUILDKIT` environment variable,
you may need to pass it along, e.g.:
>
> ```console
> DOCKER_BUILDKIT=1 DOCKER_TAG=v0.0.0 make localsecret
> ```

## Build the relayer (hermes) image
Run

```console
make build-ibc-hermes
```

## Launch a localsecret network

```console
docker compose --file deployment/dockerfiles/ibc/docker-compose.yml up
```

## Run the integration tests

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

[buildkit]: https://docs.docker.com/build/buildkit/#getting-started
[buildx]: https://docs.docker.com/build/buildx/install/#set-buildx-as-the-default-builder
