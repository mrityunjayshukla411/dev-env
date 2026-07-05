# //===--------------------------------------------------------------------===//
# Makefile to simplify building and launching environments
# //===--------------------------------------------------------------------===//

BASE_IMAGE = learn-dev-base

# Ubuntu release the base image is built from. Override on the command line, e.g.:
#   make build-base UBUNTU_IMAGE=ubuntu:22.04
UBUNTU_IMAGE ?= ubuntu:24.04

# CUDA-flavored base image, used by cuda-runtime. Override on the command line, e.g.:
#   make build-base-cuda CUDA_IMAGE=nvidia/cuda:13.3.0-runtime-ubuntu22.04
CUDA_IMAGE ?= nvidia/cuda:13.3.0-devel-ubuntu24.04
CUDA_BASE_IMAGE = learn-dev-base-cuda

# Automatically detect host UID/GID and username
UID := $(shell id -u)
GID := $(shell id -g)
USER_SUFFIX := $(shell whoami)

# Host kernel release, used by the perf capability to install a
# matching linux-tools package (see capabilities/perf.Dockerfile)
KERNEL_RELEASE := $(shell uname -r)

# Automatically detect if GPU device and its corresponding 
# docker runtime is available or not
GPU_AVAILABLE := $(shell \
	docker info 2>/dev/null | grep -qi nvidia && \
	nvidia-smi -L 2>/dev/null | grep -q "GPU" && \
	echo 1 || echo 0)

ifeq ($(GPU_AVAILABLE),1)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.gpu.yml
else
COMPOSE_FILES := -f docker-compose.yml
endif

COMPOSE = 	UID=$(UID) \
			GID=$(GID) \
			USER_SUFFIX=$(USER_SUFFIX) \
			docker compose $(COMPOSE_FILES)

# Pass NO_CACHE=1 to disable the build cache: make cpp23 NO_CACHE=1
ifdef NO_CACHE
CACHE_FLAG := --no-cache
else
CACHE_FLAG :=
endif

# //===--------------------------------------------------------------------===//
# Capabilities
#
# Optional, composable units layered on top of a base image (has-a,
# not is-a) — any environment can opt in without the language
# Dockerfiles knowing about it. Pass WITH_<CAPABILITY>=1 to enable,
# e.g.: make cpp23 WITH_PERF=1
# //===--------------------------------------------------------------------===//

ifdef WITH_PERF
LANG_BASE_DEP := build-capability-perf
LANG_BASE_IMAGE := $(BASE_IMAGE)-perf
CUDA_LANG_BASE_DEP := build-capability-perf-cuda
CUDA_LANG_BASE_IMAGE := $(CUDA_BASE_IMAGE)-perf
COMPOSE_FILES += -f docker-compose.perf.yml
else
LANG_BASE_DEP := build-base
LANG_BASE_IMAGE := $(BASE_IMAGE)
CUDA_LANG_BASE_DEP := build-base-cuda
CUDA_LANG_BASE_IMAGE := $(CUDA_BASE_IMAGE)
endif


# //===--------------------------------------------------------------------===//
# Build base development image
# //===--------------------------------------------------------------------===//

build-base:
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg UBUNTU_IMAGE=$(UBUNTU_IMAGE) \
		$(CACHE_FLAG) \
		-t $(BASE_IMAGE) \
		-f Dockerfile.base .

# Same base image, but layered on top of the CUDA runtime image instead
# of plain Ubuntu. Reuses Dockerfile.base since the CUDA runtime image
# is itself Ubuntu + apt-installable CUDA libraries.
build-base-cuda:
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg UBUNTU_IMAGE=$(CUDA_IMAGE) \
		$(CACHE_FLAG) \
		-t $(CUDA_BASE_IMAGE) \
		-f Dockerfile.base .

# //===--------------------------------------------------------------------===//
# Build capability layers
# //===--------------------------------------------------------------------===//

build-capability-perf: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg KERNEL_RELEASE=$(KERNEL_RELEASE) \
		$(CACHE_FLAG) \
		-t $(BASE_IMAGE)-perf \
		-f capabilities/perf.Dockerfile .

# Same capability, layered on top of the CUDA-flavored base instead —
# mirrors build-base/build-base-cuda so perf composes over either root.
build-capability-perf-cuda: build-base-cuda
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(CUDA_BASE_IMAGE) \
		--build-arg KERNEL_RELEASE=$(KERNEL_RELEASE) \
		$(CACHE_FLAG) \
		-t $(CUDA_BASE_IMAGE)-perf \
		-f capabilities/perf.Dockerfile .

# //===--------------------------------------------------------------------===//
# Language specific builds
# //===--------------------------------------------------------------------===//

build-rust: $(LANG_BASE_DEP)
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(LANG_BASE_IMAGE) \
		$(CACHE_FLAG) \
		-t learn-rust \
		-f languages/rust.Dockerfile .

build-go: $(LANG_BASE_DEP)
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(LANG_BASE_IMAGE) \
		$(CACHE_FLAG) \
		-t learn-go \
		-f languages/go.Dockerfile .

build-python: $(LANG_BASE_DEP)
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(LANG_BASE_IMAGE) \
		$(CACHE_FLAG) \
		-t learn-python \
		-f languages/python.Dockerfile .

build-cpp23: $(LANG_BASE_DEP)
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(LANG_BASE_IMAGE) \
		$(CACHE_FLAG) \
		-t learn-cpp23 \
		-f languages/cpp23.Dockerfile .

build-llvm: $(LANG_BASE_DEP)
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(LANG_BASE_IMAGE) \
		$(CACHE_FLAG) \
		-t learn-llvm \
		-f languages/llvm.Dockerfile .

build-cuda-runtime: $(CUDA_LANG_BASE_DEP)
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg BASE_IMAGE=$(CUDA_LANG_BASE_IMAGE) \
		$(CACHE_FLAG) \
		-t learn-cuda-runtime \
		-f languages/cuda-runtime.Dockerfile .

# //===--------------------------------------------------------------------===//
# Start environments
# //===--------------------------------------------------------------------===//

rust: build-rust
	IMAGE=learn-rust \
	CONTAINER=rust-dev-$(USER_SUFFIX) \
	COMPOSE_PROJECT_NAME=rust-$(USER_SUFFIX) \
	ENV_NAME=rust \
	$(COMPOSE) up -d --remove-orphans

go: build-go
	IMAGE=learn-go \
	CONTAINER=go-dev-$(USER_SUFFIX) \
	COMPOSE_PROJECT_NAME=go-$(USER_SUFFIX) \
	ENV_NAME=go \
	$(COMPOSE) up -d --remove-orphans

python: build-python
	IMAGE=learn-python \
	CONTAINER=python-dev-$(USER_SUFFIX) \
	COMPOSE_PROJECT_NAME=python-$(USER_SUFFIX) \
	ENV_NAME=python \
	$(COMPOSE) up -d --remove-orphans

cpp23: build-cpp23
	IMAGE=learn-cpp23 \
	CONTAINER=cpp23-dev-$(USER_SUFFIX) \
	COMPOSE_PROJECT_NAME=cpp23-$(USER_SUFFIX) \
	ENV_NAME=cpp23 \
	$(COMPOSE) up -d --remove-orphans

llvm: build-llvm
	IMAGE=learn-llvm \
	CONTAINER=llvm-dev-$(USER_SUFFIX) \
	COMPOSE_PROJECT_NAME=llvm-$(USER_SUFFIX) \
	ENV_NAME=llvm \
	$(COMPOSE) up -d --remove-orphans

cuda-runtime: build-cuda-runtime
	IMAGE=learn-cuda-runtime \
	CONTAINER=cuda-runtime-dev-$(USER_SUFFIX) \
	COMPOSE_PROJECT_NAME=cuda-runtime-$(USER_SUFFIX) \
	ENV_NAME=cuda-runtime \
	$(COMPOSE) up -d --remove-orphans

# //===--------------------------------------------------------------------===//
# Enter running container  (e.g. make cpp23-shell, make rust-shell)
# //===--------------------------------------------------------------------===//

%-shell:
	docker exec -it $*-dev-$(USER_SUFFIX) bash

# //===--------------------------------------------------------------------===//
# Stop containers  (e.g. make cpp23-stop, make rust-stop)
# //===--------------------------------------------------------------------===//

%-stop:
	docker stop $*-dev-$(USER_SUFFIX)
