# kcDevContainer

`kcDevContainer` is a standardized Docker development environment container.

It runs on `debian:stable-slim` as a non-root user with a UID and GID that default to `1000`.

## Pre-built image

```sh
docker pull ghcr.io/caseylabs/kcutils:devcontainer
```

## Setup

Build the local image:

```sh
make build
```

Run local validation checks:

```sh
make check
```

## Usage

Run and enter the container's shell:

```sh
make run
```

Override the image name or mounted work directory when needed:

```sh
make run IMAGE=kc-dev:test WORKDIR=/path/to/project
```

Remove the local image:

```sh
make clean
```

## Example

![kcDevContainer demo image](./demo.gif)
