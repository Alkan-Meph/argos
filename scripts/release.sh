#!/bin/sh
# Builds a static Linux binary of argos into dist/argos-<arch>.
#
# Usage:
#   scripts/release.sh [platform]    # default: linux/amd64
set -eu

PLATFORM="${1:-linux/amd64}"
ARCH="${PLATFORM#*/}"

docker build --platform "$PLATFORM" --target binary -o dist \
  -f scripts/Dockerfile .

rm -f "dist/argos-$ARCH"
mv dist/argos "dist/argos-$ARCH"

file "dist/argos-$ARCH" | grep -Eq "statically linked|static-pie linked" || {
  echo "ERROR: dist/argos-$ARCH is not statically linked" >&2
  exit 1
}
echo "OK: dist/argos-$ARCH"
