import 'package:flutter/services.dart';

Future<String> loadMainScript() => rootBundle.loadString('packages/nekoton_flutter_webview/assets/js/main.js');
