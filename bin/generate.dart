import 'dart:io';

import 'package:app_info_builder/app_info_builder.dart';

/// CLI entry point.
///
/// Usage:
///   dart run app_info_builder:generate
///   dart run app_info_builder:generate --class-name MyAppInfo
///   dart run app_info_builder:generate --root /path/to/project
///   dart run app_info_builder:generate --config app_info.yaml
///   dart run app_info_builder:generate --git-hash --timestamp
void main(List<String> args) {
  final cli = _parseArgs(args);

  if (cli.showHelp) {
    _printHelp();
    return;
  }

  final projectRoot = Directory(cli.root ?? Directory.current.path);
  if (!projectRoot.existsSync()) {
    stderr.writeln('ERROR: project root not found: ${projectRoot.path}');
    exit(1);
  }

  // Load the config file (if present) from the project root.
  final configPath = cli.configPath ?? 'app_info.yaml';
  final configFile = File('${projectRoot.path}/$configPath');
  var config = AppInfoConfig.fromYamlFile(configFile);

  // Override with CLI args (when set).
  config = config.copyWith(
    className: cli.className,
    outputPath: cli.outputPath,
    includeGitHash: cli.includeGitHash ? true : null,
    includeBuildTimestamp: cli.includeBuildTimestamp ? true : null,
  );

  try {
    final result = AppInfoGenerator.generate(
      projectRoot: projectRoot,
      config: config,
    );
    stdout.writeln(result.toString());
  } on AppInfoGenerationException catch (e) {
    stderr.writeln('ERROR: ${e.message}');
    exit(1);
  } catch (e, st) {
    stderr.writeln('ERROR: $e');
    stderr.writeln(st);
    exit(1);
  }
}

class _CliArgs {
  final String? root;
  final String? configPath;
  final String? className;
  final String? outputPath;
  final bool includeGitHash;
  final bool includeBuildTimestamp;
  final bool showHelp;

  const _CliArgs({
    this.root,
    this.configPath,
    this.className,
    this.outputPath,
    this.includeGitHash = false,
    this.includeBuildTimestamp = false,
    this.showHelp = false,
  });
}

_CliArgs _parseArgs(List<String> args) {
  String? root;
  String? configPath;
  String? className;
  String? outputPath;
  var gitHash = false;
  var timestamp = false;
  var help = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String? next() => (i + 1 < args.length) ? args[++i] : null;

    switch (a) {
      case '--help':
      case '-h':
        help = true;
        break;
      case '--root':
        root = next();
        break;
      case '--config':
        configPath = next();
        break;
      case '--class-name':
        className = next();
        break;
      case '--output':
        outputPath = next();
        break;
      case '--git-hash':
        gitHash = true;
        break;
      case '--timestamp':
        timestamp = true;
        break;
      default:
        stderr.writeln('Unknown arg: $a');
        exit(2);
    }
  }

  return _CliArgs(
    root: root,
    configPath: configPath,
    className: className,
    outputPath: outputPath,
    includeGitHash: gitHash,
    includeBuildTimestamp: timestamp,
    showHelp: help,
  );
}

void _printHelp() {
  stdout.writeln('''
app_info_builder — generate compile-time app metadata for Flutter.

Usage:
  dart run app_info_builder:generate [options]

Options:
  --root <path>        Project root (default: cwd)
  --config <path>      Config file relative to root (default: app_info.yaml)
  --class-name <name>  Dart class name (e.g. MyAppInfo)
  --output <path>      Output path relative to root
  --git-hash           Include git short hash in output
  --timestamp          Include UTC build timestamp in output
  -h, --help           Show this help

Config file (app_info.yaml at project root):
  class_name: MyAppInfo
  output: lib/generated/app_info.dart
  package_name_override: null
  include_git_hash: false
  include_build_timestamp: false
  extra_fields:
    buildFlavor: production

Notes:
  Only pubspec.yaml is required. Android-specific fields (appName,
  packageName) are read from android/app/src/main/AndroidManifest.xml and
  android/app/build.gradle.kts when those files exist; otherwise safe
  defaults are used.
''');
}
