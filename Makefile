# ------------------------------------------------------------
# Makefile to simplify building and launching environments
#
# Instead of remembering docker commands, you can run:
#
# make rust
# make go
# make python
# make cpp23
#
# ------------------------------------------------------------

BASE_IMAGE = learn-dev-base

# ------------------------------------------------------------
# Build base development image
# ------------------------------------------------------------

build-base:
	docker build -t $(BASE_IMAGE) -f Dockerfile.base .

# ------------------------------------------------------------
# Language specific builds
# ------------------------------------------------------------

build-rust: build-base
	docker build -t learn-rust -f languages/rust.Dockerfile .

build-go: build-base
	docker build -t learn-go -f languages/go.Dockerfile .

build-python: build-base
	docker build -t learn-python -f languages/python.Dockerfile .

build-cpp23: build-base
	docker build -t learn-cpp23 -f languages/cpp23.Dockerfile .
# ------------------------------------------------------------
# Start environments
# ------------------------------------------------------------

rust: build-rust
	IMAGE=learn-rust CONTAINER=rust-dev docker compose up -d

go: build-go
	IMAGE=learn-go CONTAINER=go-dev docker compose up -d

python: build-python
	IMAGE=learn-python CONTAINER=python-dev docker compose up -d

cpp23: build-cpp23
	IMAGE=learn-cpp23 CONTAINER=cpp23-dev docker compose up -d
# ------------------------------------------------------------
# Enter running container
# ------------------------------------------------------------

shell:
	docker exec -it $(shell docker ps -q --filter name=dev) bash

# ------------------------------------------------------------
# Stop containers
# ------------------------------------------------------------

stop:
	docker compose down
