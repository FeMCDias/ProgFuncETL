# Use the VS Code Dev Container base image for Ubuntu 22.04
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

# Install dependencies for the OCaml ETL project
RUN apt-get update && apt-get install -y --no-install-recommends \
    opam m4 pkg-config git curl build-essential libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy postCreate script to the appropriate location and set permissions
COPY postCreate.sh /home/vscode/postCreate.sh
RUN chmod +x /home/vscode/postCreate.sh

# Set the default user to vscode
USER vscode
