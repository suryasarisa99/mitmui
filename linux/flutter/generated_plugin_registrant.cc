//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_lifecycle/desktop_lifecycle_plugin.h>
#include <desktop_multi_window/desktop_multi_window_plugin.h>
#include <irondash_engine_context/irondash_engine_context_plugin.h>
#include <super_native_extensions/super_native_extensions_plugin.h>
#include <window_size/window_size_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) desktop_lifecycle_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopLifecyclePlugin");
  desktop_lifecycle_plugin_register_with_registrar(desktop_lifecycle_registrar);
  g_autoptr(FlPluginRegistrar) desktop_multi_window_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopMultiWindowPlugin");
  desktop_multi_window_plugin_register_with_registrar(desktop_multi_window_registrar);
  g_autoptr(FlPluginRegistrar) irondash_engine_context_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "IrondashEngineContextPlugin");
  irondash_engine_context_plugin_register_with_registrar(irondash_engine_context_registrar);
  g_autoptr(FlPluginRegistrar) super_native_extensions_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SuperNativeExtensionsPlugin");
  super_native_extensions_plugin_register_with_registrar(super_native_extensions_registrar);
  g_autoptr(FlPluginRegistrar) window_size_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowSizePlugin");
  window_size_plugin_register_with_registrar(window_size_registrar);
}
