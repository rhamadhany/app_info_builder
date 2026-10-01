package com.BNeoTech.app_info_builder

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * No-op Flutter plugin.
 *
 * The actual logic lives in `android/build.gradle.kts` — that file registers
 * the `generateAppInfo` task on the host project's rootProject and hooks it
 * to every `compileFlutterBuild*` task.
 *
 * This class exists only so the Flutter tool recognizes the package as a
 * valid Flutter plugin.
 */
class AppInfoBuilderPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // no-op
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // no-op
    }
}
