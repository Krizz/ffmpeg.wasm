all: dev-mt

MT_FLAGS := -sUSE_PTHREADS -pthread

DEV_ARGS := --progress=plain

DEV_CFLAGS := --profiling
DEV_MT_CFLAGS := $(DEV_CFLAGS) $(MT_FLAGS)
PROD_CFLAGS := -O3 -msimd128
PROD_MT_CFLAGS := $(PROD_CFLAGS) $(MT_FLAGS)

PKG_SUFFIX ?= -mt
FFMPEG_MT ?= yes
EXTRA_CFLAGS ?= $(PROD_MT_CFLAGS)

clean:
	rm -rf ./packages/core$(PKG_SUFFIX)/dist

.PHONY: build
build:
	$(MAKE) clean PKG_SUFFIX="$(PKG_SUFFIX)"
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	EXTRA_LDFLAGS="$(EXTRA_LDFLAGS)" \
	FFMPEG_ST="$(FFMPEG_ST)" \
	FFMPEG_MT="$(FFMPEG_MT)" \
		docker buildx build \
			--build-arg EXTRA_CFLAGS \
			--build-arg EXTRA_LDFLAGS \
			--build-arg FFMPEG_MT \
			--build-arg FFMPEG_ST \
			-o ./packages/core$(PKG_SUFFIX) \
				$(EXTRA_ARGS) \
				.

build-st:
	@echo "Single-threaded core builds are no longer supported with FFmpeg 8.0; use build-mt." >&2
	@exit 1

build-mt:
	$(MAKE) build \
			PKG_SUFFIX=-mt \
			FFMPEG_MT=yes

dev: dev-mt

dev-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

prd: prd-mt

prd-mt:
	$(MAKE) build-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"
