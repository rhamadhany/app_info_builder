#include "include/app_info_builder/app_info_builder_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "app_info_builder_plugin.h"

void AppInfoBuilderPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  app_info_builder::AppInfoBuilderPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
