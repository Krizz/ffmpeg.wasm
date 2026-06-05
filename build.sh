#!/bin/bash
#
# Build the multi-threaded (mt) core.
#
# As of FFmpeg 8.0 the command-line tools require pthreads (the CLI is built on
# a thread-based scheduler), so only the multi-threaded core can be built. The
# old single-threaded core is no longer produced. See the Dockerfile and
# build/ffmpeg-wasm.sh.
#
# Usage:
#   ./build.sh         # production build of the mt core (default)
#   ./build.sh dev     # dev build of the mt core
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

echo "==> Building multi-threaded core ($MT_TARGET)"
make "$MT_TARGET"

echo "==> Done. Built the mt core."
