# dev-env

A Docker-based collection of isolated development environments for multiple languages and toolchains, built from a shared base image and driven entirely through `make`.

## Prerequisites

- Docker Engine with the Compose plugin (`docker compose`)
- GNU Make
- Optional, for GPU workloads: NVIDIA Container Toolkit and an NVIDIA driver on the host

## Quick start

```bash
make cpp23
```

This builds the base image, builds the `cpp23` image on top of it, and starts a container with the current user's UID/GID, with `projects/` mounted at `/workspace`. Any of the environment names below can be used in place of `cpp23`.

```bash
make cpp23-shell   # open a shell in the running container
make cpp23-stop    # stop the container
```

## Available environments

| Name           | Contents                                                        | Base           |
|----------------|------------------------------------------------------------------|----------------|
| `rust`         | Rust toolchain via rustup                                         | Ubuntu         |
| `go`           | Go toolchain                                                      | Ubuntu         |
| `python`       | Python 3, pip, venv                                                | Ubuntu         |
| `cpp23`        | GCC 15, CMake, Ninja, GDB, cgdb, Valgrind                          | Ubuntu         |
| `llvm`         | GCC 15 toolchain plus Python 3, for LLVM development               | Ubuntu         |
| `cuda-runtime` | Python 3, uv, nvtop, CUDA runtime libraries                        | NVIDIA CUDA image |

Each of these corresponds to a `make <name>` target that builds and starts the environment, and a `languages/<name>.Dockerfile` that defines it.

## Project structure

```
dev-env/
├── Makefile                    build and run targets for every environment
├── Dockerfile.base              base image: common dev tools, non-root user matching host UID/GID
├── docker-compose.yml            generic service definition, parameterized by the Makefile
├── docker-compose.gpu.yml        overlay adding GPU access, included automatically when a GPU is detected
├── docker-compose.perf.yml       overlay adding the capability required to run perf
├── languages/                   one Dockerfile per environment, each extending a base image
│   ├── rust.Dockerfile
│   ├── go.Dockerfile
│   ├── python.Dockerfile
│   ├── cpp23.Dockerfile
│   ├── llvm.Dockerfile
│   └── cuda-runtime.Dockerfile
├── capabilities/                optional add-ons that can be layered onto any base image
│   └── perf.Dockerfile
└── projects/                    working directory, mounted into every container at /workspace
```

## How base images are chosen

`Dockerfile.base` does not hard-code an OS release. It takes a build argument:

```dockerfile
ARG UBUNTU_IMAGE=ubuntu:24.04
FROM ${UBUNTU_IMAGE}
```

The Makefile exposes this as `UBUNTU_IMAGE`, so the underlying OS release can be swapped without editing any Dockerfile:

```bash
make build-base UBUNTU_IMAGE=ubuntu:22.04
```

`cuda-runtime` uses the same mechanism with a different variable, `CUDA_IMAGE`, defaulting to an NVIDIA CUDA image. Its base image is built by the same `Dockerfile.base`, since NVIDIA's CUDA images are themselves Ubuntu images with CUDA libraries layered in:

```bash
make build-base-cuda CUDA_IMAGE=nvidia/cuda:13.3.0-devel-ubuntu24.04
```

Every `languages/*.Dockerfile` extends a base image the same way, through a `BASE_IMAGE` build argument, so which image sits underneath a given language environment is always a build-time choice rather than something fixed in the Dockerfile.

## Capabilities

Capabilities are optional, composable pieces of functionality that any environment can opt into, without the language Dockerfiles needing to know they exist. A capability is layered between the base image and the language image, and can be combined with any base.

Currently available:

| Flag          | Adds                          |
|---------------|--------------------------------|
| `WITH_PERF=1` | Linux `perf` profiling tools   |

```bash
make cpp23 WITH_PERF=1
make cuda-runtime WITH_PERF=1
```

### Using perf

`perf`'s wrapper refuses to run unless a binary matching the exact host kernel version is installed. The Makefile captures the host's `uname -r` as `KERNEL_RELEASE` and passes it into `capabilities/perf.Dockerfile`, which installs the matching `linux-tools-<version>` package when the exact match is available in the container's apt archives, falling back to `linux-tools-generic` otherwise.

Running `perf` also requires:

- The container to run with the `PERFMON` capability. This is granted automatically by `docker-compose.perf.yml` whenever `WITH_PERF=1` is set.
- The host's `kernel.perf_event_paranoid` sysctl to be set low enough to permit the events being collected. This is a host-wide setting and is not managed by this project.

```bash
make cpp23 WITH_PERF=1
make cpp23-shell
perf stat -e cycles,instructions -- ./your_binary
```

## GPU support

The Makefile detects whether the host has an NVIDIA GPU and the NVIDIA Docker runtime available:

```make
GPU_AVAILABLE := $(shell docker info 2>/dev/null | grep -qi nvidia && nvidia-smi -L 2>/dev/null | grep -q "GPU" && echo 1 || echo 0)
```

When detected, `docker-compose.gpu.yml` is included automatically for every environment, granting `gpus: all`. No manual configuration is required on a GPU-equipped host.

## Build options

| Variable         | Purpose                                                   | Default                        |
|-------------------|------------------------------------------------------------|---------------------------------|
| `UBUNTU_IMAGE`    | Ubuntu release the base image is built from                | `ubuntu:24.04`                  |
| `CUDA_IMAGE`      | CUDA image the CUDA-flavored base image is built from       | `nvidia/cuda:13.3.0-devel-ubuntu24.04` |
| `NO_CACHE=1`      | Disable the Docker build cache                              | off                             |
| `WITH_PERF=1`     | Layer the perf capability onto the environment being built  | off                             |

Example combining several:

```bash
make llvm UBUNTU_IMAGE=ubuntu:22.04 WITH_PERF=1 NO_CACHE=1
```

## The projects directory

`projects/` is mounted into every container at `/workspace` and is where actual project code should live. It is not tied to any single environment; the same directory is mounted regardless of which `make <name>` target is used.

## Adding a new language environment

1. Create `languages/<name>.Dockerfile`, starting with:
   ```dockerfile
   ARG BASE_IMAGE=learn-dev-base
   FROM ${BASE_IMAGE}
   ARG USERNAME=dev
   ```
   then add whatever `RUN` steps install the toolchain.
2. Add `build-<name>` and `<name>` targets to the Makefile, following the pattern of an existing entry such as `build-rust` and `rust`. Use `$(LANG_BASE_DEP)` and `$(LANG_BASE_IMAGE)` as the prerequisite and `BASE_IMAGE` build argument so the environment automatically supports every capability.

`<name>-shell` and `<name>-stop` require no additional work, since they are handled by the generic `%-shell` and `%-stop` pattern rules.

## Adding a new capability

1. Create `capabilities/<name>.Dockerfile`, starting with the same `ARG BASE_IMAGE` / `FROM ${BASE_IMAGE}` pattern used by `capabilities/perf.Dockerfile`.
2. Add a `build-capability-<name>` target (and a `build-capability-<name>-cuda` target if it should also compose over the CUDA base) mirroring `build-capability-perf`.
3. Add a `WITH_<NAME>` conditional block next to the existing `WITH_PERF` block, setting `LANG_BASE_DEP`/`LANG_BASE_IMAGE` (and their CUDA equivalents) to point at the new capability target, and appending any required Compose overlay to `COMPOSE_FILES`.

No existing language Dockerfile needs to change for a new capability to become available to it.
