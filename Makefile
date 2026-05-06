# ------------------------------------------------------------
# Makefile to simplify building and launching environments
# ------------------------------------------------------------

BASE_IMAGE = learn-dev-base

# Automatically detect host UID/GID
UID := $(shell id -u)
GID := $(shell id -g)

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

COMPOSE = UID=$(UID) GID=$(GID) docker compose $(COMPOSE_FILES)


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
	IMAGE=learn-rust CONTAINER=rust-dev $(COMPOSE) up -d --remove-orphans

go: build-go
	IMAGE=learn-go CONTAINER=go-dev $(COMPOSE) up -d --remove-orphans

python: build-python
	IMAGE=learn-python CONTAINER=python-dev $(COMPOSE) up -d --remove-orphans

cpp23: build-cpp23
	IMAGE=learn-cpp23 CONTAINER=cpp23-dev $(COMPOSE) up -d --remove-orphans

llvm: build-cpp23
	IMAGE=learn-cpp23 CONTAINER=llvm-dev $(COMPOSE) up -d --remove-orphans

# ------------------------------------------------------------
# Enter running container
# ------------------------------------------------------------

shell:
	docker exec -it $$(docker ps -q --filter name=dev) bash

# ------------------------------------------------------------
# Stop containers
# ------------------------------------------------------------

stop:
	docker compose down
