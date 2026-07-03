# ------------------------------------------------------------
# Python Development Environment
#
# Installs Python and pip on top of the base dev image.
# ------------------------------------------------------------

# Base image to extend. Override at build time, e.g.:
#   docker build --build-arg BASE_IMAGE=learn-dev-base:custom ...
ARG BASE_IMAGE=learn-dev-base
FROM ${BASE_IMAGE}
ARG USERNAME=dev

USER root

RUN apt-get update && apt-get install -y     python3     python3-pip     python3-venv

USER $USERNAME
