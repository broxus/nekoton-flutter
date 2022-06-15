#ifndef FLUTTER_PLUGIN_NEKOTON_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_NEKOTON_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace nekoton_flutter {

class NekotonFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NekotonFlutterPlugin();

  virtual ~NekotonFlutterPlugin();

  // Disallow copy and assign.
  NekotonFlutterPlugin(const NekotonFlutterPlugin&) = delete;
  NekotonFlutterPlugin& operator=(const NekotonFlutterPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace nekoton_flutter

#endif  // FLUTTER_PLUGIN_NEKOTON_FLUTTER_PLUGIN_H_
