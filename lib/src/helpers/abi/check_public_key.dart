import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

void checkPublicKey(String publicKey) => executeSync(
      () => NekotonFlutter.instance().bindings.nt_check_public_key(
            publicKey.toNativeUtf8().cast<Char>(),
          ),
    );
