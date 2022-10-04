import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/crypto/models/signed_message.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_unsigned_message_free_ptr);

class UnsignedMessage implements Finalizable {
  final Pointer<Void> _ptr;
  late int _expireAt;
  late String _hash;

  UnsignedMessage._(this._ptr);

  static Future<UnsignedMessage> create(Pointer<Void> pointer) async {
    final instance = UnsignedMessage._(pointer);
    await instance._initialize();
    return instance;
  }

  Pointer<Void> get ptr => _ptr;

  Future<void> refreshTimeout() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_refresh_timeout(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  int get expireAt => _expireAt;

  Future<int> get __expireAt async {
    final expireAt = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_unsigned_message_expire_at(
            port,
            ptr,
          ),
    );

    return expireAt as int;
  }

  String get hash => _hash;

  Future<String> get __hash async {
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

  Future<void> _updateData() async {
    _expireAt = await __expireAt;
    _hash = await __hash;
  }

  Future<void> _initialize() async {
    _nativeFinalizer.attach(this, _ptr);

    await _updateData();
  }
}
