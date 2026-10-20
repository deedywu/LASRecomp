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
- In-game touch controls provide L, Minus, Plus, R, a left movement stick and Switch-layout Y/X/B/A buttons.
  They hide and stop accepting touch automatically while an SDL gamepad is connected and active.

## Requirements

- Android SDK 36, NDK `29.0.14206865`, CMake 3.22.1 and Gradle 8.
- Your own extracted Link's Awakening v1.0.0 files in `extracted/`.
- About 6 GB on the device for `romfs.bin` plus the directly-read movies and UI/model files.

Device status:

- Builds, installs, and runs on a physical arm64 Android device (verified on vivo V2463A).
- Known limitations: frame rate is below target and colors are currently rendered incorrectly.

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

The ImGui settings menu has a separate interface-language option covering every language offered by the game:
Japanese, English, Spanish, French, German, Italian, Dutch, Russian, Korean, Simplified Chinese and Traditional
Chinese. `Auto` follows the effective game language, which in turn follows Android's preferred locale unless it is
overridden. Common menus and settings are translated; specialized text without a translation falls back to English.
Latin UI uses the available app/system face, while Japanese, Russian and Chinese use a suitable localized font.
Android additionally bundles the OFL-licensed Nanum Gothic face for Hangul coverage. These UI fonts are separate from
the shared font exposed to the game.

While the game is running, Android's Back key opens and closes the ImGui menu. Back cancels the on-screen name entry
instead when that keyboard is open.
