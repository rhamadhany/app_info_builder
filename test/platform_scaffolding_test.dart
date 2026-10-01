import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Static verification of multi-platform plugin scaffolding.
///
/// These tests do NOT invoke any actual build (no Xcode, no CMake, no
/// `flutter build linux`). They only assert that:
///   1. `pubspec.yaml` declares the plugin for every target platform.
///   2. Every platform folder + native source file exists.
///   3. The build-time hook (podspec `script_phase`, CMake
///      `add_custom_command`) is present and calls
///      `dart run app_info_builder:generate`.
void main() {
  late Directory projectRoot;

  setUpAll(() {
    // Tests run from the package root; resolve it relative to this file.
    projectRoot = Directory.current;
  });

  group('pubspec.yaml — plugin platform declaration', () {
    late Map<String, dynamic> platforms;

    setUpAll(() {
      final pubspecFile = File('${projectRoot.path}/pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue,
          reason: 'pubspec.yaml must exist at package root');

      final doc = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
      final flutter = doc['flutter'] as YamlMap;
      final plugin = flutter['plugin'] as YamlMap;
      platforms = Map<String, dynamic>.from(plugin['platforms'] as YamlMap);
    });

    for (final platform in const ['android', 'ios', 'macos', 'linux', 'windows']) {
      test('declares plugin for $platform', () {
        expect(platforms.containsKey(platform), isTrue,
            reason: '$platform must be declared in flutter.plugin.platforms');
        final cfg = platforms[platform];
        expect(cfg, isNotNull);
        if (cfg is Map) {
          expect(cfg['pluginClass'], isNotNull);
        }
      });
    }

    test('android declares package + pluginClass', () {
      final android = platforms['android'] as Map;
      expect(android['package'], 'com.BNeoTech.app_info_builder');
      expect(android['pluginClass'], 'AppInfoBuilderPlugin');
    });

    test('windows declares CApi-suffixed pluginClass', () {
      final windows = platforms['windows'] as Map;
      expect(windows['pluginClass'], 'AppInfoBuilderPluginCApi');
    });
  });

  group('iOS scaffolding', () {
    test('podspec exists', () {
      final f = File('${projectRoot.path}/ios/app_info_builder.podspec');
      expect(f.existsSync(), isTrue);
    });

    test('podspec declares a script_phase that generates app_info.dart', () {
      final f = File('${projectRoot.path}/ios/app_info_builder.podspec');
      final content = f.readAsStringSync();
      expect(content, contains('s.script_phase'));
      expect(content, contains('before_compile'));
      expect(content, contains('dart run app_info_builder:generate'));
      // Host app root must be reached via ${PROJECT_DIR}/.. (not $SRCROOT).
      expect(content, contains(r'${PROJECT_DIR}/..'));
      expect(content, isNot(contains(r'$SRCROOT')));
      // Match Flutter's own iOS template platform floor.
      expect(content, contains(":ios, '13.0'"));
    });

    test('Swift plugin class exists and is no-op', () {
      final f = File(
          '${projectRoot.path}/ios/Classes/AppInfoBuilderPlugin.swift');
      expect(f.existsSync(), isTrue);
      final content = f.readAsStringSync();
      expect(content, contains('class AppInfoBuilderPlugin'));
      expect(content, contains('register(with registrar: FlutterPluginRegistrar)'));
      expect(content, contains('import Flutter'));
    });
  });

  group('macOS scaffolding', () {
    test('podspec exists', () {
      final f = File('${projectRoot.path}/macos/app_info_builder.podspec');
      expect(f.existsSync(), isTrue);
    });

    test('podspec declares a script_phase that generates app_info.dart', () {
      final f = File('${projectRoot.path}/macos/app_info_builder.podspec');
      final content = f.readAsStringSync();
      expect(content, contains('s.script_phase'));
      expect(content, contains('before_compile'));
      expect(content, contains('dart run app_info_builder:generate'));
      expect(content, contains('FlutterMacOS'));
      expect(content, contains(r'${PROJECT_DIR}/..'));
      expect(content, isNot(contains(r'$SRCROOT')));
      // Match Flutter's own macOS template platform floor.
      expect(content, contains(":osx, '10.11'"));
    });

    test('Swift plugin class exists', () {
      final f = File(
          '${projectRoot.path}/macos/Classes/AppInfoBuilderPlugin.swift');
      expect(f.existsSync(), isTrue);
      final content = f.readAsStringSync();
      expect(content, contains('class AppInfoBuilderPlugin'));
      expect(content, contains('import FlutterMacOS'));
    });
  });

  group('Linux scaffolding', () {
    test('CMakeLists.txt exists with add_custom_command hook', () {
      final f = File('${projectRoot.path}/linux/CMakeLists.txt');
      expect(f.existsSync(), isTrue);
      final content = f.readAsStringSync();
      expect(content, contains('add_library'));
      expect(content, contains('add_custom_command'));
      expect(content, contains('dart run app_info_builder:generate'));
      expect(content, contains('WORKING_DIRECTORY'));
      // Match Flutter's plugin template: CMake 3.10 floor + _plugin suffix.
      expect(content, contains('cmake_minimum_required(VERSION 3.10)'));
      expect(content, contains('app_info_builder_plugin'));
      expect(content, isNot(contains('CMAKE_SOURCE_DIR')));
    });

    test('plugin source + header exist', () {
      expect(
        File('${projectRoot.path}/linux/app_info_builder_plugin.cc')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${projectRoot.path}/linux/include/app_info_builder/'
                'app_info_builder_plugin.h')
            .existsSync(),
        isTrue,
      );
    });

    test('header declares register_with_registrar symbol', () {
      final header = File('${projectRoot.path}/linux/include/app_info_builder/'
              'app_info_builder_plugin.h')
          .readAsStringSync();
      expect(header, contains('app_info_builder_plugin_register_with_registrar'));
      expect(header, contains('FLUTTER_PLUGIN_EXPORT'));
    });
  });

  group('Windows scaffolding', () {
    test('CMakeLists.txt exists with add_custom_command hook', () {
      final f = File('${projectRoot.path}/windows/CMakeLists.txt');
      expect(f.existsSync(), isTrue);
      final content = f.readAsStringSync();
      expect(content, contains('add_library'));
      expect(content, contains('add_custom_command'));
      expect(content, contains('dart run app_info_builder:generate'));
      expect(content, contains('WORKING_DIRECTORY'));
      expect(content, contains('cmake_policy(VERSION 3.14...3.25)'));
      expect(content, contains('app_info_builder_plugin_c_api.cpp'));
    });

    test('plugin source + C API shim + header exist', () {
      expect(
        File('${projectRoot.path}/windows/app_info_builder_plugin.cpp')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${projectRoot.path}/windows/app_info_builder_plugin.h')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${projectRoot.path}/windows/app_info_builder_plugin_c_api.cpp')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${projectRoot.path}/windows/include/app_info_builder/'
                'app_info_builder_plugin_c_api.h')
            .existsSync(),
        isTrue,
      );
    });

    test('C API header declares PluginCApiRegisterWithRegistrar symbol', () {
      final header = File('${projectRoot.path}/windows/include/app_info_builder/'
              'app_info_builder_plugin_c_api.h')
          .readAsStringSync();
      expect(header, contains('AppInfoBuilderPluginCApiRegisterWithRegistrar'));
      expect(header, contains('FLUTTER_PLUGIN_EXPORT'));
    });

    test('c_api.cpp bridges to the C++ plugin class', () {
      final cpp = File(
              '${projectRoot.path}/windows/app_info_builder_plugin_c_api.cpp')
          .readAsStringSync();
      expect(cpp, contains('AppInfoBuilderPluginCApiRegisterWithRegistrar'));
      expect(cpp, contains('AppInfoBuilderPlugin::RegisterWithRegistrar'));
    });
  });

  group('Android scaffolding (unchanged)', () {
    test('build.gradle.kts + Kotlin plugin class exist', () {
      expect(
        File('${projectRoot.path}/android/build.gradle.kts').existsSync(),
        isTrue,
      );
      expect(
        File('${projectRoot.path}/android/src/main/kotlin/com/BNeoTech/'
                'app_info_builder/AppInfoBuilderPlugin.kt')
            .existsSync(),
        isTrue,
      );
    });

    test('build.gradle.kts registers generateAppInfo + hooks compileFlutterBuild', () {
      final content = File('${projectRoot.path}/android/build.gradle.kts')
          .readAsStringSync();
      expect(content, contains('generateAppInfo'));
      expect(content, contains('compileFlutterBuild'));
      expect(content, contains('dart'));
      expect(content, contains('app_info_builder:generate'));
    });
  });
}
