import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_unsigned_message_free_ptr);

class UnsignedMessage implements Finalizable {
  final Pointer<Void> _ptr;

  UnsignedMessage(Pointer<Void> pointer) : _ptr = pointer {
    _nativeFinalizer.attach(this, _ptr);
  }

  Pointer<Void> get ptr => _ptr;

  Future<void> refreshTimeout() => executeAsync(
        (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_refresh_timeout(
              port,
              ptr,
            ),
      );

  Future<int> get expireAt async {
    final expireAt = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_expire_at(
            port,
            ptr,
          ),
    );

    return expireAt as int;
  }

  Future<String> get hash async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_hash(
            port,
            ptr,
          ),
    );

    final hash = result as String;

    return hash;
  }

  Future<SignedMessage> sign(String signature) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_sign(
            port,
            ptr,
            signature.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final signedMessage = SignedMessage.fromJson(json);

    return signedMessage;
  }
}
