#ifndef FLUTTER_PLUGIN_APP_INFO_BUILDER_PLUGIN_H_
#define FLUTTER_PLUGIN_APP_INFO_BUILDER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace app_info_builder {

class AppInfoBuilderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AppInfoBuilderPlugin();

  virtual ~AppInfoBuilderPlugin();

  // Disallow copy and assign.
  AppInfoBuilderPlugin(const AppInfoBuilderPlugin&) = delete;
  AppInfoBuilderPlugin& operator=(const AppInfoBuilderPlugin&) = delete;
};

}  // namespace app_info_builder

#endif  // FLUTTER_PLUGIN_APP_INFO_BUILDER_PLUGIN_H_
