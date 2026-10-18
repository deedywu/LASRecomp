#!/bin/bash
# Build the third-party libraries used by the Android ARM64 proof of concept.
set -euo pipefail
cd "$(dirname "$0")/../.."

SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}
NDK_VERSION=${NDK_VERSION:-29.0.14206865}
NDK="$SDK/ndk/$NDK_VERSION"
[ -x "$NDK/ndk-build" ] || { echo "Android NDK $NDK_VERSION not found under $SDK" >&2; exit 1; }
TOOLCHAIN=$(find "$NDK/toolchains/llvm/prebuilt" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "$TOOLCHAIN" ] || { echo "Android NDK toolchain not found" >&2; exit 1; }

ROOT=$PWD
DEPS=$ROOT/build/android-deps
SRC=$DEPS/src
JOBS=${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || getconf _NPROCESSORS_ONLN)}
mkdir -p "$DEPS" "$SRC"

fetch() {
    local url=$1 checksum=$2 output=$3
    if [ ! -f "$output" ]; then
        curl --http1.1 -fsSL --retry 3 --retry-delay 1 -o "$output.part" "$url"
        mv "$output.part" "$output"
    fi
    echo "$checksum  $output" | shasum -a 256 -c --quiet
}

if [ ! -d "$DEPS/SDL/.git" ]; then
    git clone --depth 1 --branch release-3.4.18 https://github.com/libsdl-org/SDL.git "$DEPS/SDL"
fi

SHADERC_OUT=$DEPS/shaderc
if [ ! -f "$SHADERC_OUT/libs/c++_static/arm64-v8a/libshaderc.a" ]; then
    SHADERC="$NDK/sources/third_party/shaderc"
    [ -f "$SHADERC/Android.mk" ] || { echo "The NDK's shaderc sources are missing" >&2; exit 1; }
    mkdir -p "$SHADERC_OUT/obj" "$SHADERC_OUT/libs"
    "$NDK/ndk-build" -C "$SHADERC" NDK_PROJECT_PATH="$SHADERC" APP_BUILD_SCRIPT="$SHADERC/Android.mk" \
        APP_PLATFORM=android-33 APP_ABI=arm64-v8a APP_STL=c++_static NDK_OUT="$SHADERC_OUT/obj" \
        NDK_LIBS_OUT="$SHADERC_OUT/libs" -j"$JOBS" libshaderc_combined
fi

VMA_ARCHIVE=$SRC/vma-3.3.0.tar.gz
fetch https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/refs/tags/v3.3.0.tar.gz \
    c4f6bbe6b5a45c2eb610ca9d231158e313086d5b1a40c9922cb42b597419b14e "$VMA_ARCHIVE"
if [ ! -f "$DEPS/vma/include/vma/vk_mem_alloc.h" ]; then
    mkdir -p "$DEPS/vma/include/vma"
    tar -xOf "$VMA_ARCHIVE" VulkanMemoryAllocator-3.3.0/include/vk_mem_alloc.h > \
        "$DEPS/vma/include/vma/vk_mem_alloc.h"
fi

FF_ARCHIVE=$SRC/ffmpeg-9.0.2.tar.xz
fetch https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz \
    8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e "$FF_ARCHIVE"
FF_PREFIX=$DEPS/ffmpeg
if [ ! -f "$FF_PREFIX/lib/libavcodec.a" ]; then
    FF_SRC=$DEPS/ffmpeg-src
    rm -rf "$FF_SRC"
    mkdir -p "$FF_SRC"
    tar -xf "$FF_ARCHIVE" -C "$FF_SRC" --strip-components 1
    (
        cd "$FF_SRC"
        ./configure --prefix="$FF_PREFIX" --target-os=android --arch=aarch64 --enable-cross-compile \
            --sysroot="$TOOLCHAIN/sysroot" --cc="$TOOLCHAIN/bin/aarch64-linux-android33-clang" \
            --cxx="$TOOLCHAIN/bin/aarch64-linux-android33-clang++" --ar="$TOOLCHAIN/bin/llvm-ar" \
            --ranlib="$TOOLCHAIN/bin/llvm-ranlib" --strip="$TOOLCHAIN/bin/llvm-strip" \
            --enable-static --disable-shared --enable-pic --disable-asm --extra-cflags=-fPIC \
            --disable-autodetect --disable-programs --disable-doc --disable-network --disable-avdevice \
            --disable-avfilter --disable-swresample --disable-everything --enable-protocol=file \
            --enable-demuxer=matroska,mov --enable-decoder=vp9,vp8,vorbis,h264,aac \
            --enable-parser=vp9,vp8,vorbis,h264,aac
        make -j"$JOBS"
        make install
    )
fi

echo "Android dependencies ready under $DEPS"
