import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointed.dart';
import 'models/signed_message.dart';

class UnsignedMessage implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  UnsignedMessage(this._ptr);

  Future<void> refreshTimeout() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_refresh_timeout(
            port,
            ptr,
          ),
    );
  }

  Future<int> get expireAt async {
    final ptr = await clonePtr();

    final expireAt = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_expire_at(
            port,
            ptr,
          ),
    );

    return expireAt as int;
  }

  Future<String> get hash async {
    final ptr = await clonePtr();

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
    final ptr = await clonePtr();

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

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('UnsignedMessage use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_unsigned_message_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_unsigned_message_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });
}
