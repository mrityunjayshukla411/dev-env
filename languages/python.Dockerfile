# ------------------------------------------------------------
# Python Development Environment
#
# Installs Python and pip on top of the base dev image.
# ------------------------------------------------------------

FROM learn-dev-base

USER root

RUN apt-get update && apt-get install -y     python3     python3-pip     python3-venv

USER ubuntu
