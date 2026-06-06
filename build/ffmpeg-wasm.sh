#!/bin/bash
# `-o <OUTPUT_FILE_NAME>` must be provided when using this build script.
# ex:
#     bash ffmpeg-wasm.sh -o ffmpeg.js

set -euo pipefail

EXPORT_NAME="createFFmpegCore"

CONF_FLAGS=(
  -I.
  -I./src
  -I./src/fftools
  -I./compat/stdbit                        # FFmpeg's C23 <stdbit.h> shim, used by fftools/ffmpeg_dec.c. FFmpeg's own configure adds this when the compiler lacks stdbit.h (emsdk's clang does); this separate emcc build needs it too.
  -I$INSTALL_DIR/include 
  -L$INSTALL_DIR/lib 
  -Llibavcodec 
  -Llibavdevice 
  -Llibavfilter 
  -Llibavformat 
  -Llibavutil
  -Llibswresample
  -Llibswscale
  -lavcodec
  -lavdevice
  -lavfilter
  -lavformat
  -lavutil
  -lswresample
  -lswscale
  # NOTE: libpostproc was removed in FFmpeg 8.0, so there is no -lpostproc here.
  -Wno-deprecated-declarations 
  $LDFLAGS 
  -sENVIRONMENT=worker
  -sWASM_BIGINT                            # enable big int support
  -sUSE_SDL=2                              # use emscripten SDL2 lib port
  -sSTACK_SIZE=5MB                         # increase stack size to support libopus
  -sMODULARIZE                             # modularized to use as a library
  # NOTE: INITIAL_MEMORY is large and load-bearing, not just a hint. Memory
  # growth deadlocks in this build: the FFmpeg 8.0 scheduler blocks the runtime
  # "main thread" (the core Web Worker) inside sch_wait for the whole run, so a
  # shared-memory grow requested by a stage thread can never be coordinated and
  # the transcode hangs. Reserve enough up front that a run never needs to grow.
  ${FFMPEG_MT:+ -sINITIAL_MEMORY=512MB -sALLOW_MEMORY_GROWTH -sMAXIMUM_MEMORY=4GB}
  ${FFMPEG_MT:+ -sPTHREAD_POOL_SIZE=32}    # pre-spawned worker pool. Counter-intuitively this must stay generous even though codec-internal threading is disabled (see ffmpeg_dec.c / ffmpeg_mux_init.c): because the scheduler blocks the runtime main thread for the whole run, exited stage threads cannot have their workers reclaimed to the pool mid-run, so the pool must cover the *cumulative* thread count of a run, not just the concurrent peak. Shrinking to 16 deadlocks a simple transcode
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH -sMAXIMUM_MEMORY=4GB} # Use just enough memory as memory usage can grow
  -sEXPORT_NAME="$EXPORT_NAME"             # required in browser env, so that user can access this module from window object
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js) # exported functions
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js) # exported built-in functions
  -lworkerfs.js
  --pre-js src/bind/ffmpeg/bind.js        # extra bindings, contains most of the ffmpeg.wasm javascript code
  # ffmpeg source code (fftools, n8.0 layout). The CLI was split into a
  # thread-based scheduler plus per-stage modules, and ffprobe's output moved
  # to the textformat/ writers, so the file list is much larger than in 5.1.4.
  # graphprint.c is our no-op stub (see src/fftools/graph/graphprint.c) which
  # lets us drop the resources/resman codegen.
  src/fftools/cmdutils.c
  src/fftools/opt_common.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_dec.c
  src/fftools/ffmpeg_demux.c
  src/fftools/ffmpeg_enc.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_mux_init.c
  src/fftools/ffmpeg_opt.c
  src/fftools/ffmpeg_sched.c
  src/fftools/sync_queue.c
  src/fftools/thread_queue.c
  src/fftools/graph/graphprint.c
  src/fftools/ffprobe.c
  src/fftools/textformat/avtextformat.c
  src/fftools/textformat/tf_compact.c
  src/fftools/textformat/tf_default.c
  src/fftools/textformat/tf_flat.c
  src/fftools/textformat/tf_ini.c
  src/fftools/textformat/tf_json.c
  src/fftools/textformat/tf_mermaid.c
  src/fftools/textformat/tf_xml.c
  src/fftools/textformat/tw_avio.c
  src/fftools/textformat/tw_buffer.c
  src/fftools/textformat/tw_stdout.c
)

emcc "${CONF_FLAGS[@]}" $@
