//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import desktop_lifecycle
import desktop_multi_window
import device_info_plus
import irondash_engine_context
import super_native_extensions
import window_size

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DesktopLifecyclePlugin.register(with: registry.registrar(forPlugin: "DesktopLifecyclePlugin"))
  FlutterMultiWindowPlugin.register(with: registry.registrar(forPlugin: "FlutterMultiWindowPlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  IrondashEngineContextPlugin.register(with: registry.registrar(forPlugin: "IrondashEngineContextPlugin"))
  SuperNativeExtensionsPlugin.register(with: registry.registrar(forPlugin: "SuperNativeExtensionsPlugin"))
  WindowSizePlugin.register(with: registry.registrar(forPlugin: "WindowSizePlugin"))
}
