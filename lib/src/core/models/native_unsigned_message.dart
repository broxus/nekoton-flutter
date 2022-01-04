import 'dart:async';
import 'dart:ffi';

import 'package:synchronized/synchronized.dart';

import '../../models/nekoton_exception.dart';

class NativeUnsignedMessage {
  final _lock = Lock();
  Completer<void>? _completer;
  Pointer<Void>? _ptr;

  NativeUnsignedMessage(this._ptr);

  bool get isNull => _ptr == null;

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) => _lock.synchronized(() async {
        await _completer?.future;

        if (_ptr == null) {
          throw UnsignedMessageNotFoundException();
        } else {
          _completer = Completer<void>();
          return function(_ptr!)
            ..then((_) {
              if (_completer != null && !_completer!.isCompleted) {
                _completer?.complete();
              }
            }).onError((_, __) {
              if (_completer != null && !_completer!.isCompleted) {
                _completer?.complete();
              }
            });
        }
      });

  Future<void> free() => _lock.synchronized(() async {
        await _completer?.future;
        _completer = Completer<void>();

        if (_ptr == null) {
          throw UnsignedMessageNotFoundException();
        } else {
          _ptr = null;
        }

        if (_completer != null && !_completer!.isCompleted) {
          _completer?.complete();
        }
      });
}
