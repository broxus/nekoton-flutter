import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:tuple/tuple.dart';

typedef StorageGet = Future<String?> Function(String key);

typedef StorageSet = Future<void> Function({
  required String key,
  required String value,
});

typedef StorageSetUnchecked = void Function({
  required String key,
  required String value,
});

typedef StorageRemove = Future<void> Function(String key);

typedef StorageRemoveUnchecked = void Function(String key);

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_storage_free_ptr);

class Storage implements Finalizable {
  late final Pointer<Void> _ptr;
  final _getPort = ReceivePort();
  final _setPort = ReceivePort();
  final _setUncheckedPort = ReceivePort();
  final _removePort = ReceivePort();
  final _removeUncheckedPort = ReceivePort();
  late final StreamSubscription<Tuple2<String, String>> _getSubscription;
  late final StreamSubscription<Tuple3<String, String, String>> _setSubscription;
  late final StreamSubscription<Tuple2<String, String>> _setUncheckedSubscription;
  late final StreamSubscription<Tuple2<String, String>> _removeSubscription;
  late final StreamSubscription<String> _removeUncheckedSubscription;
  final StorageGet _get;
  final StorageSet _set;
  final StorageSetUnchecked _setUnchecked;
  final StorageRemove _remove;
  final StorageRemoveUnchecked _removeUnchecked;

  Storage({
    required StorageGet get,
    required StorageSet set,
    required StorageSetUnchecked setUnchecked,
    required StorageRemove remove,
    required StorageRemoveUnchecked removeUnchecked,
  })  : _get = get,
        _set = set,
        _setUnchecked = setUnchecked,
        _remove = remove,
        _removeUnchecked = removeUnchecked {
    _getSubscription = _getPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final tx = json.first as String;
      final key = json.last as String;

      return Tuple2(tx, key);
    }).listen(_getRequestHandler);

    _setSubscription = _setPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final tx = json.first as String;
      final key = json[1] as String;
      final value = json.last as String;

      return Tuple3(tx, key, value);
    }).listen(_setRequestHandler);

    _setUncheckedSubscription = _setUncheckedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final key = json.first as String;
      final value = json.last as String;

      return Tuple2(key, value);
    }).listen(_setUncheckedRequestHandler);

    _removeSubscription = _removePort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final tx = json.first as String;
      final key = json.last as String;

      return Tuple2(tx, key);
    }).listen(_removeRequestHandler);

    _removeUncheckedSubscription =
        _removeUncheckedPort.cast<String>().listen(_removeUncheckedRequestHandler);

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_storage_create(
            _getPort.sendPort.nativePort,
            _setPort.sendPort.nativePort,
            _setUncheckedPort.sendPort.nativePort,
            _removePort.sendPort.nativePort,
            _removeUncheckedPort.sendPort.nativePort,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);
  }

  Pointer<Void> get ptr => _ptr;

  Future<void> dispose() async {
    await _getSubscription.cancel();
    await _setSubscription.cancel();
    await _setUncheckedSubscription.cancel();
    await _removeSubscription.cancel();
    await _removeUncheckedSubscription.cancel();

    _getPort.close();
    _setPort.close();
    _setUncheckedPort.close();
    _removePort.close();
    _removeUncheckedPort.close();
  }

  Future<void> _getRequestHandler(Tuple2<String, String> event) async {
    final tx = toPtrFromAddress(event.item1);

    String? ok;
    String? err;

    try {
      ok = await _get(event.item2);
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_optional_string(
          tx,
          ok?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _setRequestHandler(Tuple3<String, String, String> event) async {
    final tx = toPtrFromAddress(event.item1);

    String? err;

    try {
      await _set(
        key: event.item2,
        value: event.item3,
      );
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_unit(
          tx,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _setUncheckedRequestHandler(Tuple2<String, String> event) async {
    try {
      _setUnchecked(
        key: event.item1,
        value: event.item2,
      );
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }

  Future<void> _removeRequestHandler(Tuple2<String, String> event) async {
    final tx = toPtrFromAddress(event.item1);

    String? err;

    try {
      await _remove(event.item2);
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_unit(
          tx,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _removeUncheckedRequestHandler(String event) async {
    try {
      _removeUnchecked(event);
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }
}
