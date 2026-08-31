# syntax=docker/dockerfile:1
# Static release build for argos.
#
#   docker build --platform linux/amd64 --target binary -o dist -f scripts/Dockerfile .
#
# Layering follows dune's documented Docker pattern: dependencies are
# built by the @pkg-install alias in a layer keyed only on dune-project
# and dune.lock, so source changes never rebuild them.
# https://dune.readthedocs.io/en/latest/reference/aliases/pkg-install.html

FROM ocaml/opam:alpine-3.24@sha256:4e065e459d9e56e5232b3e0c6f6be33dc168bfa1b7f25cba85f798f19049536e AS builder

# linux-headers: required by liburing (uring package, via eio_linux).
# gmp-dev: required by zarith (caqti 3 -> x509 -> mirage-crypto -> zarith).
# sqlite-static: static variant of libsqlite3 for the final link.
RUN sudo apk add --no-cache gmp-dev linux-headers sqlite-dev sqlite-static

# dune with package management support.
RUN opam update --yes \
 && opam install --yes 'dune>=3.24' \
 && opam clean --yes --download-cache --logs

WORKDIR /build

# Dependency layer: invalidated only when the manifest or the lock
# changes.
COPY --chown=opam:opam dune-project ./
COPY --chown=opam:opam dune.lock ./dune.lock/
RUN opam exec -- dune build --profile static @pkg-install

# Project layer: invalidated by source changes, rebuilds only argos.
COPY --chown=opam:opam . .
RUN opam exec -- dune build --profile static bin/main.exe

FROM scratch AS binary
COPY --from=builder /build/_build/default/bin/main.exe /argos
