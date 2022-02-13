import 'dart:ffi';

import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../models/pointed.dart';

class UnsignedMessage implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  UnsignedMessage(this._ptr);

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Unsigned message use after free');

        final ptr = bindings().clone_unsigned_message_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Unsigned message use after free');

        bindings().free_unsigned_message_ptr(
          _ptr!,
        );

        _ptr = null;
      });
}
