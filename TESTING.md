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

## Launch a localsecret network

```console
docker compose --file deployment/dockerfiles/ibc/dev.yml up
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

## Making modifications to the code
See the `volumes` field in the `dev.yml` compose file to mount specifc source code,
which can be available in a container used to re-build specific components.

As time progresses, the development workflow will be improved.

## Tips
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
