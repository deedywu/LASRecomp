#!/bin/bash
# Build the local ARM64 Android proof-of-concept APK from the user's own extracted v1.0.0 files.
set -euo pipefail
cd "$(dirname "$0")/../.."

tools/android/build_deps.sh
[ -d extracted/exefs ] || { echo "Extracted v1.0.0 game files are required in extracted/" >&2; exit 1; }
make gen build/inc/smaa_hlsl.inc

GRADLE=${GRADLE:-$(command -v gradle || true)}
[ -n "$GRADLE" ] || { echo "Set GRADLE to a Gradle 8 executable, or build android/ in Android Studio" >&2; exit 1; }
"$GRADLE" -p android assembleDebug
echo "$PWD/android/app/build/outputs/apk/debug/app-debug.apk"
