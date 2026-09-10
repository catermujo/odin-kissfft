#!/usr/bin/env bash

set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$BASE/kissfft"
REVISION=e5e3fac46e0d94a8f8170c06706b7a4218828333
REMOTE=https://github.com/mborgerding/kissfft.git
CC="${CC:-cc}"
AR="${AR:-ar}"

case "$(uname -s):$(uname -m)" in
    Darwin:arm64 | Darwin:aarch64) PLATFORM=darwin_arm64; LIB_NAME=kissfft.darwin.a ;;
    Darwin:x86_64 | Darwin:amd64) PLATFORM=darwin_x64; LIB_NAME=kissfft.darwin.a ;;
    Linux:x86_64 | Linux:amd64) PLATFORM=linux_x64; LIB_NAME=kissfft.linux.a ;;
    Linux:aarch64 | Linux:arm64) PLATFORM=linux_arm64; LIB_NAME=kissfft.linux.a ;;
    *) echo "Unsupported platform: $(uname -s) $(uname -m)" >&2; exit 1 ;;
esac

command -v git >/dev/null 2>&1 || { echo "Missing required command: git" >&2; exit 1; }
command -v "$CC" >/dev/null 2>&1 || { echo "Missing required C compiler: $CC" >&2; exit 1; }
command -v "$AR" >/dev/null 2>&1 || { echo "Missing required archiver: $AR" >&2; exit 1; }

if [ -e "$SOURCE_DIR" ] && [ ! -d "$SOURCE_DIR/.git" ]; then
    echo "KISS FFT source path exists but is not a git checkout: $SOURCE_DIR" >&2
    exit 1
fi
if [ ! -d "$SOURCE_DIR/.git" ]; then
    git clone --no-checkout "$REMOTE" "$SOURCE_DIR"
    git -C "$SOURCE_DIR" checkout --detach "$REVISION"
fi
if [ "$(git -C "$SOURCE_DIR" rev-parse HEAD)" != "$REVISION" ]; then
    echo "KISS FFT source checkout does not match pinned commit: $REVISION" >&2
    exit 1
fi

BUILD_DIR="$BASE/build_$PLATFORM"
OUTPUT_DIR="$BASE/$PLATFORM"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
"$CC" -std=c11 -O3 -DNDEBUG -fPIC -I"$BASE" -c "$BASE/bridge_f32.c" -o "$BUILD_DIR/bridge_f32.o"
"$CC" -std=c11 -O3 -DNDEBUG -fPIC -I"$BASE" -c "$BASE/bridge_f64.c" -o "$BUILD_DIR/bridge_f64.o"
"$AR" rcs "$OUTPUT_DIR/$LIB_NAME" "$BUILD_DIR/bridge_f32.o" "$BUILD_DIR/bridge_f64.o"

echo "KISS FFT static build completed successfully!"
