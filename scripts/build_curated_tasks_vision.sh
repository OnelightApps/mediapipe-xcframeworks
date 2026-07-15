#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/vision"
INPUT_DIR="$BUILD_DIR/input"
OUTPUT_DIR="$BUILD_DIR/output"
SOURCE_URL="https://github.com/OnelightApps/mediapipe-xcframeworks/releases/download/0.10.21/MediaPipeTasksVision.xcframework.zip"
SOURCE_ZIP="$INPUT_DIR/MediaPipeTasksVision.xcframework.zip"
XCFRAMEWORK="$OUTPUT_DIR/MediaPipeTasksVisionCurated.xcframework"

rm -rf "$BUILD_DIR"
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

if [ -n "${SOURCE_XCFRAMEWORK:-}" ]; then
  cp -R "$SOURCE_XCFRAMEWORK" "$XCFRAMEWORK"
else
  curl -L "$SOURCE_URL" -o "$SOURCE_ZIP"
  unzip -q "$SOURCE_ZIP" -d "$INPUT_DIR/extracted"
  source_framework="$(find "$INPUT_DIR/extracted" -type d -name 'MediaPipeTasksVision.xcframework' -print -quit)"
  test -n "$source_framework"
  cp -R "$source_framework" "$XCFRAMEWORK"
fi

while IFS= read -r info_plist; do
  /usr/libexec/PlistBuddy -c "Clear dict" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string MediaPipeTasksVision" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.google.mediapipe.tasks.vision" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleName string MediaPipeTasksVision" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string FMWK" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.10.21" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms array" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms:0 string iPhoneOS" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$info_plist"
  /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 16.0" "$info_plist"
done < <(find "$XCFRAMEWORK" -type f -path '*/MediaPipeTasksVision.framework/Info.plist')

while IFS= read -r info_plist; do
  test "$(plutil -extract CFBundlePackageType raw "$info_plist")" = "FMWK"
  test "$(plutil -extract MinimumOSVersion raw "$info_plist")" = "16.0"
  test "$(plutil -extract CFBundleShortVersionString raw "$info_plist")" = "0.10.21"
  test "$(plutil -extract CFBundleVersion raw "$info_plist")" = "1"
done < <(find "$XCFRAMEWORK" -type f -path '*/MediaPipeTasksVision.framework/Info.plist')

ditto -c -k --sequesterRsrc --keepParent \
  "$XCFRAMEWORK" \
  "$OUTPUT_DIR/MediaPipeTasksVisionCurated.xcframework.zip"

swift package compute-checksum \
  "$OUTPUT_DIR/MediaPipeTasksVisionCurated.xcframework.zip"
