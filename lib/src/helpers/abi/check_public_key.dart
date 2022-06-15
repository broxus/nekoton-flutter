import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../ffi_utils.dart';

void checkPublicKey(String publicKey) => executeSync(
      () => NekotonFlutter.instance().bindings.nt_check_public_key(
            publicKey.toNativeUtf8().cast<Char>(),
          ),
    );
