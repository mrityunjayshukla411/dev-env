# ------------------------------------------------------------
# Makefile to simplify building and launching environments
# ------------------------------------------------------------

BASE_IMAGE = learn-dev-base

# Automatically detect host UID/GID
UID := $(shell id -u)
GID := $(shell id -g)

# Automatically detect if GPU device is available or not
GPU_AVAILABLE := $(shell nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | grep -q . && echo 1 || echo 0)

COMPOSE_CMD = docker compose
ifeq ($(GPU_AVAILABLE),1)
	COMPOSE_CMD = docker compose --profile gpu
endif


# ------------------------------------------------------------
# Build base development image
# ------------------------------------------------------------

build-base:
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t $(BASE_IMAGE) \
		-f Dockerfile.base .

# ------------------------------------------------------------
# Language specific builds
# ------------------------------------------------------------

build-rust: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t learn-rust \
		-f languages/rust.Dockerfile .

build-go: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t learn-go \
		-f languages/go.Dockerfile .

build-python: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t learn-python \
		-f languages/python.Dockerfile .

build-cpp23: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t learn-cpp23 \
		-f languages/cpp23.Dockerfile .

# ------------------------------------------------------------
# Start environments
# ------------------------------------------------------------

rust: build-rust
	UID=$(UID) GID=$(GID) IMAGE=learn-rust CONTAINER=rust-dev $(COMPOSE_CMD) up -d

go: build-go
	UID=$(UID) GID=$(GID) IMAGE=learn-go CONTAINER=go-dev $(COMPOSE_CMD) up -d

python: build-python
	UID=$(UID) GID=$(GID) IMAGE=learn-python CONTAINER=python-dev $(COMPOSE_CMD) up -d

cpp23: build-cpp23
	UID=$(UID) GID=$(GID) IMAGE=learn-cpp23 CONTAINER=cpp23-dev $(COMPOSE_CMD) up -d

llvm: build-cpp23
	UID=$(UID) GID=$(GID) IMAGE=learn-cpp23 CONTAINER=llvm-dev $(COMPOSE_CMD) up -d

# ------------------------------------------------------------
# Enter running container
# ------------------------------------------------------------

shell:
	docker exec -it $$(docker ps -q --filter name=dev) bash

# ------------------------------------------------------------
# Stop containers
# ------------------------------------------------------------

stop:
	$(COMPOSE_CMD) down
