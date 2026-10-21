#!/bin/bash
# Build the third-party libraries used by one Android ABI.
set -euo pipefail
cd "$(dirname "$0")/../.."

SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}
if command -v cygpath >/dev/null 2>&1 && [[ "$SDK" == *\\* ]]; then
    SDK=$(cygpath -u "$SDK")
fi
NDK_VERSION=${NDK_VERSION:-29.0.14206865}
NDK="$SDK/ndk/$NDK_VERSION"
NDK_BUILD="$NDK/ndk-build"
if [ ! -x "$NDK_BUILD" ] && [ -f "$NDK/ndk-build.cmd" ]; then
    NDK_BUILD="$NDK/ndk-build.cmd"
fi
[ -f "$NDK_BUILD" ] || { echo "Android NDK $NDK_VERSION not found under $SDK" >&2; exit 1; }
TOOLCHAIN=$(find "$NDK/toolchains/llvm/prebuilt" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "$TOOLCHAIN" ] || { echo "Android NDK toolchain not found" >&2; exit 1; }

ROOT=$PWD
DEPS=$ROOT/build/android-deps
SRC=$DEPS/src
JOBS=${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || getconf _NPROCESSORS_ONLN)}
HOST_CC_BIN=${HOST_CC:-gcc}
if command -v cygpath >/dev/null 2>&1 && [[ "$HOST_CC_BIN" == *\\* ]]; then
    HOST_CC_BIN=$(cygpath -u "$HOST_CC_BIN")
fi
ANDROID_ABI=${ANDROID_ABI:-arm64-v8a}
case "$ANDROID_ABI" in
    arm64-v8a) FFMPEG_ARCH=aarch64; CLANG_TRIPLE=aarch64-linux-android; DEPS_SUFFIX= ;;
    x86_64) FFMPEG_ARCH=x86_64; CLANG_TRIPLE=x86_64-linux-android; DEPS_SUFFIX=-x86_64 ;;
    *) echo "Unsupported Android ABI: $ANDROID_ABI" >&2; exit 1 ;;
esac
mkdir -p "$DEPS" "$SRC"

fetch() {
    local url=$1 checksum=$2 output=$3
    if [ ! -f "$output" ]; then
        curl --http1.1 -fsSL --retry 3 --retry-delay 1 -o "$output.part" "$url"
        mv "$output.part" "$output"
    fi
    if command -v shasum >/dev/null 2>&1; then
        echo "$checksum  $output" | shasum -a 256 -c --quiet
    else
        echo "$checksum  $output" | sha256sum -c --quiet
    fi
}

if [ ! -d "$DEPS/SDL/.git" ]; then
    git clone --depth 1 --branch release-3.4.18 https://github.com/libsdl-org/SDL.git "$DEPS/SDL"
fi

SHADERC_OUT=$DEPS/shaderc$DEPS_SUFFIX
if [ ! -f "$SHADERC_OUT/libs/c++_static/$ANDROID_ABI/libshaderc.a" ]; then
    SHADERC="$NDK/sources/third_party/shaderc"
    [ -f "$SHADERC/Android.mk" ] || { echo "The NDK's shaderc sources are missing" >&2; exit 1; }
    mkdir -p "$SHADERC_OUT/obj" "$SHADERC_OUT/libs"
    if ! "$NDK_BUILD" -C "$SHADERC" NDK_PROJECT_PATH="$SHADERC" APP_BUILD_SCRIPT="$SHADERC/Android.mk" \
            APP_PLATFORM=android-33 APP_ABI="$ANDROID_ABI" APP_STL=c++_static NDK_OUT="$SHADERC_OUT/obj" \
            NDK_LIBS_OUT="$SHADERC_OUT/libs" -j"$JOBS" libshaderc_combined; then
        # ndk-build.cmd writes combine.ar with CRLF and literal quotes when called from an MSYS shell.
        # llvm-ar's MRI parser rejects both, so normalize the file and finish that final step directly.
        COMBINE="$SHADERC_OUT/obj/local/$ANDROID_ABI/combine.ar"
        OUT="$SHADERC_OUT/obj/local/$ANDROID_ABI/libshaderc_combined.a"
        [ -f "$COMBINE" ] || exit 1
        tr -d '\r' < "$COMBINE" | sed -e 's/^"//' -e 's/"[[:space:]]*$//' > "$COMBINE.lf"
        mv "$COMBINE.lf" "$COMBINE"
        (cd "$(dirname "$COMBINE")" && "$TOOLCHAIN/bin/llvm-ar" -M < combine.ar)
        "$TOOLCHAIN/bin/llvm-strip" --strip-debug "$OUT"
        mkdir -p "$SHADERC_OUT/libs/c++_static/$ANDROID_ABI"
        cp "$OUT" "$SHADERC_OUT/libs/c++_static/$ANDROID_ABI/libshaderc.a"
    fi
fi

VMA_ARCHIVE=$SRC/vma-3.3.0.tar.gz
fetch https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/refs/tags/v3.3.0.tar.gz \
    c4f6bbe6b5a45c2eb610ca9d231158e313086d5b1a40c9922cb42b597419b14e "$VMA_ARCHIVE"
if [ ! -f "$DEPS/vma/include/vma/vk_mem_alloc.h" ]; then
    mkdir -p "$DEPS/vma/include/vma"
    tar -xOf "$VMA_ARCHIVE" VulkanMemoryAllocator-3.3.0/include/vk_mem_alloc.h > \
        "$DEPS/vma/include/vma/vk_mem_alloc.h"
fi

# Custom Vulkan drivers bypass Android's system loader. Use current headers for
# Turnip extensions and dispatch every Vulkan call through volk.
VULKAN_HEADERS_ARCHIVE=$SRC/Vulkan-Headers-1.4.350.1.tar.gz
fetch https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-1.4.350.1.tar.gz \
    6d1bb65e49520344cc0a48af3dc02e993781efff14c7ebdcb8ae9fa23ddf7e83 "$VULKAN_HEADERS_ARCHIVE"
if [ ! -f "$DEPS/vulkan/include/vulkan/vulkan_core.h" ]; then
    rm -rf "$DEPS/vulkan"
    mkdir -p "$DEPS/vulkan/include"
    tar -xf "$VULKAN_HEADERS_ARCHIVE" -C "$DEPS/vulkan/include" --strip-components 2 \
        Vulkan-Headers-vulkan-sdk-1.4.350.1/include/vulkan \
        Vulkan-Headers-vulkan-sdk-1.4.350.1/include/vk_video
fi

VOLK_ARCHIVE=$SRC/volk-1.4.350.1.tar.gz
fetch https://github.com/zeux/volk/archive/refs/tags/vulkan-sdk-1.4.350.1.tar.gz \
    078a9411298e4e0f60f5f5398c890783427c25a414619294ca8e69587bbd5eae "$VOLK_ARCHIVE"
if [ ! -f "$DEPS/volk/volk.c" ]; then
    rm -rf "$DEPS/volk"
    mkdir -p "$DEPS/volk"
    tar -xOf "$VOLK_ARCHIVE" volk-vulkan-sdk-1.4.350.1/volk.c > "$DEPS/volk/volk.c"
    tar -xOf "$VOLK_ARCHIVE" volk-vulkan-sdk-1.4.350.1/volk.h > "$DEPS/volk/volk.h"
    tar -xOf "$VOLK_ARCHIVE" volk-vulkan-sdk-1.4.350.1/LICENSE.md > "$DEPS/volk/LICENSE.md"
fi

FF_ARCHIVE=$SRC/ffmpeg-9.0.2.tar.xz
fetch https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz \
    8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e "$FF_ARCHIVE"
FF_PREFIX=$DEPS/ffmpeg$DEPS_SUFFIX
if [ ! -f "$FF_PREFIX/lib/libavcodec.a" ]; then
    FF_SRC=$DEPS/ffmpeg-src$DEPS_SUFFIX
    rm -rf "$FF_SRC"
    mkdir -p "$FF_SRC"
    tar -xf "$FF_ARCHIVE" -C "$FF_SRC" --strip-components 1
    (
        cd "$FF_SRC"
        ./configure --prefix="$FF_PREFIX" --target-os=android --arch="$FFMPEG_ARCH" --enable-cross-compile \
            --host-cc="$HOST_CC_BIN" \
            --sysroot="$TOOLCHAIN/sysroot" --cc="$TOOLCHAIN/bin/${CLANG_TRIPLE}33-clang" \
            --cxx="$TOOLCHAIN/bin/${CLANG_TRIPLE}33-clang++" --ar="$TOOLCHAIN/bin/llvm-ar" \
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

echo "Android $ANDROID_ABI dependencies ready under $DEPS"
