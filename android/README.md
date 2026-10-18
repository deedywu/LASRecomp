# Android proof of concept

This is an experimental Android port. It reuses SDL 3 and the Vulkan backend and compiles the generated game code into
a local APK. ARM64 is used on phones; an x86-64 build is included for emulators such as MuMu. It does not contain game
files in the repository.

Current status:

- Android resource screen: select a primary-storage folder, validate `exefs/main`, `exefs/sdk`, `exefs/main.npdm`
  and `romfs.bin`, and only enable Play when they are present.
- ARM64 fixed-address guest memory and Vulkan 1.3 were verified on an Adreno 830 phone and Android Emulator.
- The native x86-64 build reaches the title screen on MuMu Player and renders the opening at about 60 FPS. Later
  gameplay and the real-device path remain experimental.
- No touch controls yet. A keyboard or controller is expected.

## Requirements

- Android SDK 36, NDK `29.0.14206865`, CMake 3.22.1 and Gradle 8.
- Your own extracted Link's Awakening v1.0.0 files in `extracted/`.
- About 6 GB on the device for `romfs.bin` plus the directly-read movies and UI/model files.

Build locally:

```sh
tools/android/build.sh
```

The script downloads/builds SDL 3.4.18, LGPL FFmpeg 9.0.2, shaderc and Vulkan Memory Allocator under ignored
`build/android-deps/`, runs `make gen`, then builds the APK. Set `GRADLE=/path/to/gradle` when Gradle is not on PATH.

The APK includes generated code from the user's game copy. It is for local testing only and must not be committed or
distributed. The repository's rule against Nintendo files also applies to APKs, generated code and device data.

## Device layout

The default resource root is `/sdcard/LASRecomp`, with the game under `/sdcard/LASRecomp/extracted`. The launcher can
select another folder in primary storage. `romfs.bin` serves normal RomFS reads; movies and a small set of UI/model
files are also read directly from `extracted/romfs` by the movie and texture-patching paths.

Android's `NotoSansCJK-Regular.ttc` uses CFF outlines that the game's font engine cannot consume. Devices with a
TrueType `DroidSansFallback` use it automatically; otherwise place a legally usable TrueType CJK font at
`/sdcard/LASRecomp/fonts/android-cjk.ttf`.
