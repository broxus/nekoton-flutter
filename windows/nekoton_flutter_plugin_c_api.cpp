#include "include/nekoton_flutter/nekoton_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "nekoton_flutter_plugin.h"

void NekotonFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  nekoton_flutter::NekotonFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
