#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
INPUT_DIR="$BUILD_DIR/input"
OUTPUT_DIR="$BUILD_DIR/output"
SOURCE_URL="https://github.com/OnelightApps/mediapipe-xcframeworks/releases/download/0.10.21/MediaPipeTasksCommon.xcframework.zip"
SOURCE_ZIP="${SOURCE_ZIP:-$INPUT_DIR/MediaPipeTasksCommon.xcframework.zip}"
XCFRAMEWORK="$OUTPUT_DIR/MediaPipeTasksCommonCurated.xcframework"

rm -rf "$BUILD_DIR"
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

if [ -n "${SOURCE_XCFRAMEWORK:-}" ]; then
  cp -R "$SOURCE_XCFRAMEWORK" "$XCFRAMEWORK"
else
  curl -L "$SOURCE_URL" -o "$SOURCE_ZIP"
  unzip -q "$SOURCE_ZIP" -d "$INPUT_DIR/extracted"
  source_framework="$(find "$INPUT_DIR/extracted" -type d -name 'MediaPipeTasksCommon.xcframework' -print -quit)"
  test -n "$source_framework"
  cp -R "$source_framework" "$XCFRAMEWORK"
fi

duplicate_objects=(
  'MPPBaseOptions.o'
  'MPPBaseOptions+Helpers.o'
  'MPPCategory.o'
  'MPPCategory+Helpers.o'
  'MPPClassificationResult.o'
  'MPPClassificationResult+Helpers.o'
  'MPPCommonUtils.o'
  'MPPCosineSimilarity.o'
  'MPPEmbedding.o'
  'MPPEmbedding+Helpers.o'
  'MPPEmbeddingResult.o'
  'MPPEmbeddingResult+Helpers.o'
  'MPPTaskInfo.o'
  'MPPTaskOptions.o'
  'MPPTaskResult.o'
  'MPPTaskRunner.o'
  'metal_shared_resources.o'
  'packet.o'
)

prune_archive() {
  local archive="$1"
  local object

  for object in "${duplicate_objects[@]}"; do
    while ar -t "$archive" | grep -Fx "$object" >/dev/null; do
      ar -d "$archive" "$object"
    done
  done
  ranlib "$archive"
}

device_archive="$XCFRAMEWORK/ios-arm64/MediaPipeTasksCommon.framework/MediaPipeTasksCommon"
prune_archive "$device_archive"

simulator_archive="$XCFRAMEWORK/ios-arm64_x86_64-simulator/MediaPipeTasksCommon.framework/MediaPipeTasksCommon"
simulator_slices="$BUILD_DIR/simulator-slices"
mkdir -p "$simulator_slices"

for architecture in arm64 x86_64; do
  slice="$simulator_slices/$architecture.a"
  lipo "$simulator_archive" -thin "$architecture" -output "$slice"
  prune_archive "$slice"
done

lipo -create \
  "$simulator_slices/arm64.a" \
  "$simulator_slices/x86_64.a" \
  -output "$simulator_archive"

for archive in "$device_archive" "$simulator_archive"; do
  for object in "${duplicate_objects[@]}"; do
    if ar -t "$archive" 2>/dev/null | grep -Fx "$object" >/dev/null; then
      echo "error: duplicate object remains: $object in $archive" >&2
      exit 1
    fi
  done
done

ditto -c -k --sequesterRsrc --keepParent \
  "$XCFRAMEWORK" \
  "$OUTPUT_DIR/MediaPipeTasksCommonCurated.xcframework.zip"

swift package compute-checksum \
  "$OUTPUT_DIR/MediaPipeTasksCommonCurated.xcframework.zip"
