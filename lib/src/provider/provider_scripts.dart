import 'package:flutter/services.dart';

Future<String> loadMainScript() => rootBundle.loadString('packages/nekoton_flutter/assets/js/main.js');
