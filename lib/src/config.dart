import 'dart:io';

import 'package:yaml/yaml.dart';

/// Generator configuration.
///
/// Resolved from (highest priority last):
/// 1. Defaults (constants in this class)
/// 2. `app_info.yaml` at the project root
/// 3. CLI args
class AppInfoConfig {
  /// Dart class name to generate.
  /// Example: `MyAppInfo`, `BuildInfo`.
  final String className;

  /// Output path relative to the project root.
  final String outputPath;

  /// When set, overrides `packageName` read from `build.gradle.kts`
  /// (Android-only). Useful for non-Android host projects that want a
  /// stable, explicit package identifier.
  final String? packageNameOverride;

  /// Include `gitHash` in the output.
  final bool includeGitHash;

  /// Include `buildTimestamp` (UTC ISO 8601) in the output.
  final bool includeBuildTimestamp;

  /// Custom extra fields — key: field name (String const), value: literal.
  /// Example: `{'buildFlavor': 'production'}`.
  final Map<String, String> extraFields;

  const AppInfoConfig({
    this.className = 'AppInfo',
    this.outputPath = 'lib/generated/app_info.dart',
    this.packageNameOverride,
    this.includeGitHash = false,
    this.includeBuildTimestamp = false,
    this.extraFields = const {},
  });

  AppInfoConfig copyWith({
    String? className,
    String? outputPath,
    String? packageNameOverride,
    bool? includeGitHash,
    bool? includeBuildTimestamp,
    Map<String, String>? extraFields,
  }) {
    return AppInfoConfig(
      className: className ?? this.className,
      outputPath: outputPath ?? this.outputPath,
      packageNameOverride: packageNameOverride ?? this.packageNameOverride,
      includeGitHash: includeGitHash ?? this.includeGitHash,
      includeBuildTimestamp:
          includeBuildTimestamp ?? this.includeBuildTimestamp,
      extraFields: extraFields ?? this.extraFields,
    );
  }

  /// Read configuration from an `app_info.yaml` file.
  /// Returns the default config when the file is missing.
  static AppInfoConfig fromYamlFile(File file) {
    if (!file.existsSync()) return const AppInfoConfig();

    final doc = loadYaml(file.readAsStringSync());
    if (doc is! Map) return const AppInfoConfig();

    final map = Map<String, dynamic>.from(doc);

    return AppInfoConfig(
      className: (map['class_name'] as String?) ?? 'AppInfo',
      outputPath: (map['output'] as String?) ?? 'lib/generated/app_info.dart',
      packageNameOverride: map['package_name_override'] as String?,
      includeGitHash: (map['include_git_hash'] as bool?) ?? false,
      includeBuildTimestamp:
          (map['include_build_timestamp'] as bool?) ?? false,
      extraFields: _parseExtraFields(map['extra_fields']),
    );
  }

  static Map<String, String> _parseExtraFields(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  @override
  String toString() =>
      'AppInfoConfig(className: $className, outputPath: $outputPath, '
      'packageNameOverride: $packageNameOverride, '
      'includeGitHash: $includeGitHash, '
      'includeBuildTimestamp: $includeBuildTimestamp, '
      'extraFields: $extraFields)';
}
