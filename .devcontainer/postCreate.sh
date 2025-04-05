#!/bin/bash
echo "Setting up OCaml ETL environment..."

# Initialize opam and create switch if not already created
opam init -y --disable-sandboxing
opam switch create 4.14.0 || true  # If it exists, do nothing
opam switch 4.14.0
eval $(opam env)

# Install OCaml packages
opam install -y dune utop ocaml-lsp-server csv sqlite3 cohttp-lwt-unix lwt lwt_ppx ounit2 lwt_ssl

# Ensure environment is updated
eval $(opam env)

echo "Environment setup complete."
