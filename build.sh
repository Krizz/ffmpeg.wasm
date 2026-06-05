#!/bin/bash
#
# Build ffmpeg.wasm.
#
# Builds the multi-threaded (mt) wasm core and, by default, the JS packages
# (@ffmpeg/ffmpeg, @ffmpeg/util) on top of it.
#
# As of FFmpeg 8.0 the command-line tools require pthreads (the CLI is built on
# a thread-based scheduler), so only the multi-threaded core can be built. The
# old single-threaded core is no longer produced. See the Dockerfile and
# build/ffmpeg-wasm.sh.
#
# Usage:
#   ./build.sh              # production build: mt core + JS packages
#   ./build.sh dev          # dev build: mt core + JS packages
#
# Environment variables:
#   BUILD_JS=no             # build only the wasm core, skip the JS packages
#   EXTRA_ARGS="..."        # forwarded to `docker buildx` (e.g. cache flags in CI):
#                           #   EXTRA_ARGS="--cache-from=type=local,src=build-cache-mt \
#                           #               --cache-to=type=local,dest=build-cache-mt,mode=max"
#
set -euo pipefail

MODE="${1:-prd}"

case "$MODE" in
  prd)
    MT_TARGET=prd-mt
    ;;
  dev)
    MT_TARGET=dev-mt
    ;;
  *)
    echo "Unknown mode: $MODE (expected 'prd' or 'dev')" >&2
    exit 1
    ;;
esac

BUILD_JS="${BUILD_JS:-yes}"
EXTRA_ARGS="${EXTRA_ARGS:-}"

echo "==> Building multi-threaded core ($MT_TARGET)"
make "$MT_TARGET" EXTRA_ARGS="$EXTRA_ARGS"

if [ "$BUILD_JS" = "yes" ]; then
  echo "==> Building JS packages (npm run build)"
  npm run build
else
  echo "==> Skipping JS packages (BUILD_JS=$BUILD_JS)"
fi

echo "==> Done."
