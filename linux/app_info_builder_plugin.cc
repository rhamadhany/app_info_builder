// No-op Flutter plugin for Linux.
//
// Actual logic runs at build time via the CMake `add_custom_command` in
// CMakeLists.txt — it calls `dart run app_info_builder:generate`.
#include "include/app_info_builder/app_info_builder_plugin.h"

#include <flutter_linux/flutter_linux.h>

struct _AppInfoBuilderPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AppInfoBuilderPlugin, app_info_builder_plugin, g_object_get_type())

static void app_info_builder_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(app_info_builder_plugin_parent_class)->dispose(object);
}

static void app_info_builder_plugin_class_init(AppInfoBuilderPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = app_info_builder_plugin_dispose;
}

static void app_info_builder_plugin_init(AppInfoBuilderPlugin* self) {}

void app_info_builder_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  AppInfoBuilderPlugin* plugin = APP_INFO_BUILDER_PLUGIN(
      g_object_new(app_info_builder_plugin_get_type(), nullptr));
  g_object_unref(plugin);
}
