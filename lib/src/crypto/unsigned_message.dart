import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import 'models/signed_message.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_unsigned_message_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class UnsignedMessage {
  late final PointerWrapper pointerWrapper;

  UnsignedMessage(Pointer<Void> pointer) {
    pointerWrapper = PointerWrapper(pointer);
    _attach(pointerWrapper);
  }

  Future<void> refreshTimeout() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_refresh_timeout(
            port,
            pointerWrapper.ptr,
          ),
    );
  }

  Future<int> get expireAt async {
    final expireAt = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_expire_at(
            port,
            pointerWrapper.ptr,
          ),
    );

    return expireAt as int;
  }

  Future<String> get hash async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_hash(
            port,
            pointerWrapper.ptr,
          ),
    );

    final hash = result as String;

    return hash;
  }

  Future<SignedMessage> sign(String signature) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_sign(
            port,
            pointerWrapper.ptr,
            signature.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final signedMessage = SignedMessage.fromJson(json);

    return signedMessage;
  }
}
