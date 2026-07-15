# mediapipe-xcframeworks

SPM binary target hosting for MediaPipe Tasks Vision XCFrameworks.

## Curated Tasks Common

`MediaPipeTasksCommon` 0.10.21 contains Objective-C task classes and MediaPipe
packet implementation objects that are also present in the dynamic
`MediaPipeCommonGraphLibraries` binary. Linking both unchanged produces
duplicate Objective-C classes and duplicate MediaPipe type registrations.

Build the curated archive with:

```bash
./scripts/build_curated_tasks_common.sh
```

The script removes only objects already owned by CommonGraph and preserves the
device arm64 plus simulator arm64/x86_64 slices.

`build_curated_tasks_vision.sh` corrects the embedded framework metadata used
by App Store validation, including `MinimumOSVersion` and the framework package
type.
