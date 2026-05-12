# ------------------------------------------------------------
# Makefile to simplify building and launching environments
# ------------------------------------------------------------

BASE_IMAGE = learn-dev-base

# Automatically detect host UID/GID and username
UID := $(shell id -u)
GID := $(shell id -g)
USER_SUFFIX := $(shell whoami)

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

COMPOSE = UID=$(UID) GID=$(GID) USER_SUFFIX=$(USER_SUFFIX) docker compose $(COMPOSE_FILES)

# Pass NO_CACHE=1 to disable the build cache: make cpp23 NO_CACHE=1
ifdef NO_CACHE
CACHE_FLAG := --no-cache
else
CACHE_FLAG :=
endif


# ------------------------------------------------------------
# Build base development image
# ------------------------------------------------------------

build-base:
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		$(CACHE_FLAG) \
		-t $(BASE_IMAGE) \
		-f Dockerfile.base .

# ------------------------------------------------------------
# Language specific builds
# ------------------------------------------------------------

build-rust: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		$(CACHE_FLAG) \
		-t learn-rust \
		-f languages/rust.Dockerfile .

build-go: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		$(CACHE_FLAG) \
		-t learn-go \
		-f languages/go.Dockerfile .

build-python: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		$(CACHE_FLAG) \
		-t learn-python \
		-f languages/python.Dockerfile .

build-cpp23: build-base
	docker build \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		$(CACHE_FLAG) \
		-t learn-cpp23 \
		-f languages/cpp23.Dockerfile .

# ------------------------------------------------------------
# Start environments
# ------------------------------------------------------------

rust: build-rust
	IMAGE=learn-rust CONTAINER=rust-dev-$(USER_SUFFIX) $(COMPOSE) up -d --remove-orphans

go: build-go
	IMAGE=learn-go CONTAINER=go-dev-$(USER_SUFFIX) $(COMPOSE) up -d --remove-orphans

python: build-python
	IMAGE=learn-python CONTAINER=python-dev-$(USER_SUFFIX) $(COMPOSE) up -d --remove-orphans

cpp23: build-cpp23
	IMAGE=learn-cpp23 CONTAINER=cpp23-dev-$(USER_SUFFIX) $(COMPOSE) up -d --remove-orphans

llvm: build-cpp23
	IMAGE=learn-cpp23 CONTAINER=llvm-dev-$(USER_SUFFIX) $(COMPOSE) up -d --remove-orphans

# ------------------------------------------------------------
# Enter running container
# ------------------------------------------------------------

shell:
	docker exec -it $$(docker ps -q --filter name=-dev-$(USER_SUFFIX)) bash

# ------------------------------------------------------------
# Stop containers
# ------------------------------------------------------------

stop:
	docker compose down
