import 'dart:io';

import 'package:app_info_builder/app_info_builder.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('aib_test_');
    final r = tempRoot.path;
    _writeFile('$r/pubspec.yaml', 'name: demo\nversion: 2.3.4+56\n');
    _writeFile(
      '$r/android/app/src/main/AndroidManifest.xml',
      '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
          '    <application\n'
          '        android:label="Demo App"\n'
          '        android:name=".MainActivity"/>\n'
          '</manifest>\n',
    );
    _writeFile(
      '$r/android/app/build.gradle.kts',
      'android {\n'
          '    namespace = "com.BNeoTech.demo"\n'
          '    defaultConfig {\n'
          '        applicationId = "com.BNeoTech.demo.prod"\n'
          '    }\n'
          '}\n',
    );
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('AppInfoGenerator — basic generation', () {
    test('generate reads metadata and writes the output file', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(className: 'DemoInfo'),
      );

      expect(result.appName, 'Demo App');
      expect(result.packageName, 'com.BNeoTech.demo.prod');
      expect(result.version, '2.3.4');
      expect(result.buildNumber, '56');
      expect(result.fullVersion, '2.3.4+56');

      final out = File(result.outputPath);
      expect(out.existsSync(), isTrue);
      final content = out.readAsStringSync();
      expect(content, contains('class DemoInfo {'));
      expect(content, contains("static const String appName = 'Demo App';"));
      expect(
        content,
        contains("static const String packageName = 'com.BNeoTech.demo.prod';"),
      );
      expect(content, contains("static const String version = '2.3.4';"));
      expect(content, contains("static const String buildNumber = '56';"));
      expect(
        content,
        contains("static const String fullVersion = '2.3.4+56';"),
      );

      // Source header mentions only the files that were actually read.
      expect(
        content,
        contains(
          '// Source: pubspec.yaml, AndroidManifest.xml, build.gradle.kts',
        ),
      );
      // Comment must be platform-neutral, not Android-only.
      expect(content, contains('native build hook'));
      expect(content, isNot(contains('Gradle task')));
    });

    test('falls back to namespace when applicationId is missing', () {
      final r = tempRoot.path;
      _writeFile(
        '$r/android/app/build.gradle.kts',
        'android {\n  namespace = "com.ns.only"\n}\n',
      );

      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(className: 'DemoInfo'),
      );

      expect(result.packageName, 'com.ns.only');
    });

    test('version without build number → buildNumber defaults to 0', () {
      final r = tempRoot.path;
      _writeFile('$r/pubspec.yaml', 'name: demo\nversion: 1.0.0\n');
      final result = AppInfoGenerator.generate(projectRoot: tempRoot);
      expect(result.version, '1.0.0');
      expect(result.buildNumber, '0');
      expect(result.fullVersion, '1.0.0+0');
    });

    test('packageNameOverride is respected', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(packageNameOverride: 'com.custom.app'),
      );
      expect(result.packageName, 'com.custom.app');
    });

    test('extraFields are written as const String', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(
          className: 'DemoInfo',
          extraFields: {'buildFlavor': 'production', 'apiEnv': 'stable'},
        ),
      );
      final content = File(result.outputPath).readAsStringSync();
      expect(
        content,
        contains("static const String buildFlavor = 'production';"),
      );
      expect(content, contains("static const String apiEnv = 'stable';"));
    });

    test('custom output path is respected', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(outputPath: 'lib/foo/bar.dart'),
      );
      expect(result.outputPath, endsWith('lib/foo/bar.dart'));
      expect(File(result.outputPath).existsSync(), isTrue);
    });

    test('timestamp is included when includeBuildTimestamp is true', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(includeBuildTimestamp: true),
      );
      expect(result.buildTimestamp, isNotNull);
      final content = File(result.outputPath).readAsStringSync();
      expect(content, contains('static const String buildTimestamp ='));
    });
  });

  group('AppInfoGenerator — non-Android host project', () {
    setUp(() {
      // Simulate an iOS/macOS/Linux/Windows-only Flutter project:
      // no android/ folder at all.
      final r = tempRoot.path;
      Directory('$r/android').deleteSync(recursive: true);
    });

    test('generate still succeeds without AndroidManifest.xml / build.gradle.kts', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(className: 'DemoInfo'),
      );

      // Cross-platform fields are still populated.
      expect(result.version, '2.3.4');
      expect(result.buildNumber, '56');
      expect(result.fullVersion, '2.3.4+56');

      // Android-only fields fall back to safe defaults.
      expect(result.appName, 'Unknown');
      expect(result.packageName, 'com.example.unknown');

      final content = File(result.outputPath).readAsStringSync();
      // Source header only lists pubspec.yaml — the Android files were absent.
      expect(content, contains('// Source: pubspec.yaml\n'));
      expect(content, isNot(contains('AndroidManifest.xml,')));
      expect(content, isNot(contains('build.gradle.kts,')));
    });

    test('packageNameOverride is still applied without build.gradle.kts', () {
      final result = AppInfoGenerator.generate(
        projectRoot: tempRoot,
        config: const AppInfoConfig(packageNameOverride: 'com.override.pkg'),
      );
      expect(result.packageName, 'com.override.pkg');
    });
  });

  group('AppInfoGenerator — error handling', () {
    test('throws when pubspec.yaml is missing', () {
      final r = tempRoot.path;
      File('$r/pubspec.yaml').deleteSync();
      expect(
        () => AppInfoGenerator.generate(projectRoot: tempRoot),
        throwsA(isA<AppInfoGenerationException>()),
      );
    });

    test('does not throw when AndroidManifest.xml is missing (optional)', () {
      final r = tempRoot.path;
      File('$r/android/app/src/main/AndroidManifest.xml').deleteSync();
      final result = AppInfoGenerator.generate(projectRoot: tempRoot);
      expect(result.appName, 'Unknown');
    });

    test('does not throw when build.gradle.kts is missing (optional)', () {
      final r = tempRoot.path;
      File('$r/android/app/build.gradle.kts').deleteSync();
      final result = AppInfoGenerator.generate(projectRoot: tempRoot);
      expect(result.packageName, 'com.example.unknown');
    });
  });

  group('AppInfoConfig — YAML loader', () {
    test('returns defaults when the file is missing', () {
      final r = tempRoot.path;
      final cfg = AppInfoConfig.fromYamlFile(File('$r/missing.yaml'));
      expect(cfg.className, 'AppInfo');
      expect(cfg.outputPath, 'lib/generated/app_info.dart');
      expect(cfg.includeGitHash, isFalse);
    });

    test('parses YAML correctly', () {
      final r = tempRoot.path;
      _writeFile('$r/app_info.yaml', '''
class_name: MyCustomInfo
output: lib/custom/info.dart
include_git_hash: true
include_build_timestamp: true
extra_fields:
  buildFlavor: staging
''');
      final cfg = AppInfoConfig.fromYamlFile(File('$r/app_info.yaml'));
      expect(cfg.className, 'MyCustomInfo');
      expect(cfg.outputPath, 'lib/custom/info.dart');
      expect(cfg.includeGitHash, isTrue);
      expect(cfg.includeBuildTimestamp, isTrue);
      expect(cfg.extraFields['buildFlavor'], 'staging');
    });
  });
}

void _writeFile(String path, String content) {
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(content);
}
