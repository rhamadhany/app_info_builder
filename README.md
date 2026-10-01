# app_info_builder

Generate **compile-time app metadata** for Flutter — no platform channel, no runtime delay. Scaffolding is provided for **Android, iOS, macOS, Linux, and Windows**; **only Android has been tested end-to-end** (see [Verification status](#verification-status)).

`app_info_builder` reads metadata at **build time** via an automatic hook in the host project's native build system (Gradle on Android, CocoaPods `script_phase` on iOS/macOS, CMake on Linux/Windows), then writes a Dart file containing `const` values — ready to use directly from code without `async`.

## Setup

### 1. Add the dependency

```yaml
# pubspec.yaml
dependencies:      # ← MUST be here (not dev_dependencies)
  app_info_builder:
    git:
      url: https://github.com/rhamadhany/app_info_builder.git
      # ref: v0.0.2   # optional: pin to a tag or commit
```

> **Note:** It must be under `dependencies`, because Flutter only recognizes plugins from there. APK overhead ~10 KB — negligible.

### 2. (Optional) Create `app_info.yaml` at the project root

```yaml
class_name: MyAppInfo           # default: AppInfo
output: lib/generated/app_info.dart
# include_git_hash: false
# include_build_timestamp: false
# extra_fields:
#   buildFlavor: production
#   apiEnv: stable
```

### 3. (Optional) Ignore the generated folder

```gitignore
# .gitignore
/lib/generated/
```

### 4. Use it in code

```dart
import 'package:myapp/generated/app_info.dart';

Text('v${MyAppInfo.fullVersion}');        // "1.0.5+6"
Text(MyAppInfo.appName);                   // "MyApp"
Text(MyAppInfo.packageName);               // "com.example.myapp"
```

**Done.** No copy-pasting build scripts. No `apply from`. No edits inside `android/`, `ios/`, `macos/`, `linux/`, or `windows/`.

## How it works

```
flutter pub get
    ↓
Flutter registers the app_info_builder plugin in .flutter-plugins-dependencies
    ↓
Host build system picks up the plugin's native folder
  Android → Gradle     iOS/macOS → CocoaPods     Linux/Windows → CMake
    ↓
Platform hook registers a pre-build step that runs:
    ↓
dart run app_info_builder:generate
    ↓
Writes lib/generated/app_info.dart (const)
    ↓
Build resumes with the new file
```

The platform-specific hook is a thin shim. All parsing logic lives in Dart and is identical across platforms — see the table in [Platform support](#platform-support) for the exact hook used per platform.

## Generated fields

| Field | Source | Notes |
|---|---|---|
| `appName` | `android:label` in `AndroidManifest.xml` | Android-only — skipped if the file is absent |
| `packageName` | `applicationId` (fallback: `namespace`) in `build.gradle.kts` | Android-only — skipped if the file is absent |
| `version` | `version:` in `pubspec.yaml` (part before `+`) | Cross-platform |
| `buildNumber` | `version:` in `pubspec.yaml` (part after `+`) | Cross-platform |
| `fullVersion` | `"$version+$buildNumber"` | Cross-platform |
| `gitHash` | `git rev-parse --short HEAD` | Optional, cross-platform |
| `buildTimestamp` | UTC ISO 8601 | Optional, cross-platform |
| `extra_fields.*` | From the config file | Optional, cross-platform |

Only `pubspec.yaml` is required. Android-specific fields are emitted when `AndroidManifest.xml` / `build.gradle.kts` exist in the host project; otherwise they fall back to a safe default (e.g. `packageName` → `com.example.unknown`).

## Manual generate (optional)

If you need to regenerate without a full build:

```bash
dart run app_info_builder:generate
dart run app_info_builder:generate --help
```

Options:
- `--root <path>` — Project root (default: cwd)
- `--config <path>` — Config file relative to root (default: `app_info.yaml`)
- `--class-name <name>` — Dart class name
- `--output <path>` — Output path relative to root
- `--git-hash` — Include git short hash
- `--timestamp` — Include UTC build timestamp

Or via Gradle on Android (from the `android/` folder):

```bash
cd android && ./gradlew :app:generateAppInfo
```

The CLI is the only entry point that matters — every platform hook calls the exact same command, so a manual `dart run app_info_builder:generate` produces identical output regardless of platform.

## Platform support

| Platform | Build hook | Regenerates before | Tested? |
|---|---|---|---|
| Android | Gradle task `generateAppInfo` (Kotlin DSL) | `compileFlutterBuild*` | ✅ Yes |
| iOS | CocoaPods `script_phase` (before_compile) | Xcode compile phase | ❌ Not yet |
| macOS | CocoaPods `script_phase` (before_compile) | Xcode compile phase | ❌ Not yet |
| Linux | CMake `add_custom_command` | plugin target build | ❌ Not yet |
| Windows | CMake `add_custom_command` | plugin target build | ❌ Not yet |

All hooks call the same CLI: `dart run app_info_builder:generate`. Metadata parsing itself is platform-agnostic and only needs `pubspec.yaml` (plus `AndroidManifest.xml` / `build.gradle.kts` for Android-specific fields).

## Verification status

- **Android — verified end-to-end.** `flutter build apk --debug` was run on an existing Android host; the `generateAppInfo` Gradle task was triggered automatically before `compileFlutterBuildDebug` and regenerated `lib/generated/app_info.dart` in a fresh build (file was deleted beforehand and reappeared with a new timestamp).
- **iOS / macOS / Linux / Windows — not yet built.** The scaffolding (podspec `script_phase`, CMake `add_custom_command`, Windows C API shim) is committed and statically asserted by `test/platform_scaffolding_test.dart`, but no `flutter build` has been executed for these platforms from this repository.
- Contributions that run the platform builds on matching hosts (or CI runners) and report results are welcome.

## Limitations

- **Does not detect `--build-name` / `--build-number`** from `flutter build` — always reads from `pubspec.yaml`
- `dart` must be on `PATH` at build time
- First use requires `flutter pub get` so Flutter registers the plugin
- See [Verification status](#verification-status) for which platforms have been built end-to-end.

## License

Licensed under the Apache License, Version 2.0 — see [LICENSE](LICENSE) for details.
