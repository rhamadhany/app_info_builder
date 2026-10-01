# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. Do not increase this version.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "app_info_builder")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "app_info_builder_plugin")

list(APPEND PLUGIN_SOURCES
  "app_info_builder_plugin.cpp"
  "app_info_builder_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/app_info_builder/app_info_builder_plugin_c_api.h"
  "app_info_builder_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
set(app_info_builder_bundled_libraries
  ""
  PARENT_SCOPE
)

# === Build-time hook: regenerate lib/generated/app_info.dart ==============
#
# Walk up from the plugin source dir until we find the host app's pubspec.yaml.
# The plugin runs from <host>/windows/flutter/ephemeral/.plugin_symlinks/...,
# so the source-dir variables here do NOT reliably point at the host root.
function(app_info_find_host_root _out_var)
  set(_dir "${CMAKE_CURRENT_SOURCE_DIR}")
  foreach(_i RANGE 1 8)
    if(EXISTS "${_dir}/pubspec.yaml")
      set(${_out_var} "${_dir}" PARENT_SCOPE)
      return()
    endif()
    get_filename_component(_dir "${_dir}/.." ABSOLUTE)
  endforeach()
  set(${_out_var} "" PARENT_SCOPE)
endfunction()

app_info_find_host_root(APP_INFO_HOST_ROOT)

if(APP_INFO_HOST_ROOT)
  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/app_info_generated.stamp"
    COMMAND ${CMAKE_COMMAND} -E touch "${CMAKE_CURRENT_BINARY_DIR}/app_info_generated.stamp"
    COMMAND dart run app_info_builder:generate
    WORKING_DIRECTORY "${APP_INFO_HOST_ROOT}"
    COMMENT "[app_info_builder] Regenerating app_info.dart in ${APP_INFO_HOST_ROOT}"
    VERBATIM
  )
  add_custom_target(app_info_generate ALL
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/app_info_generated.stamp"
  )
  add_dependencies(${PLUGIN_NAME} app_info_generate)
else()
  message(WARNING "[app_info_builder] host project root (pubspec.yaml) not found; skipping app_info generation.")
endif()
