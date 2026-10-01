// No-op Flutter plugin for Windows.
//
// Actual logic runs at build time via the CMake `add_custom_command` in
// CMakeLists.txt — it calls `dart run app_info_builder:generate`.
#include "app_info_builder_plugin.h"

#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace app_info_builder {

// static
void AppInfoBuilderPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  registrar->AddPlugin(std::make_unique<AppInfoBuilderPlugin>());
}

AppInfoBuilderPlugin::AppInfoBuilderPlugin() {}

AppInfoBuilderPlugin::~AppInfoBuilderPlugin() {}

}  // namespace app_info_builder
