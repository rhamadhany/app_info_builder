//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <app_info_builder/app_info_builder_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) app_info_builder_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AppInfoBuilderPlugin");
  app_info_builder_plugin_register_with_registrar(app_info_builder_registrar);
}
