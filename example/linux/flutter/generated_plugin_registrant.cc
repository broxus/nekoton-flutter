//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <nekoton_flutter/nekoton_flutter_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) nekoton_flutter_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NekotonFlutterPlugin");
  nekoton_flutter_plugin_register_with_registrar(nekoton_flutter_registrar);
}
