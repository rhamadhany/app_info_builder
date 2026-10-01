import FlutterMacOS
import Foundation

/// No-op Flutter plugin for macOS.
///
/// Actual logic runs at build time via the `script_phase` defined in
/// `app_info_builder.podspec` — it calls `dart run app_info_builder:generate`.
public class AppInfoBuilderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // no-op
    }
}
