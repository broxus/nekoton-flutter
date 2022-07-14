import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/storage_get_request.dart';
import 'package:nekoton_flutter/src/external/models/storage_remove_request.dart';
import 'package:nekoton_flutter/src/external/models/storage_remove_unchecked_request.dart';
import 'package:nekoton_flutter/src/external/models/storage_set_request.dart';
import 'package:nekoton_flutter/src/external/models/storage_set_unchecked_request.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_storage_free_ptr);

class Storage implements Finalizable {
  late final Pointer<Void> _ptr;
  final _getPort = ReceivePort();
  final _setPort = ReceivePort();
  final _setUncheckedPort = ReceivePort();
  final _removePort = ReceivePort();
  final _removeUncheckedPort = ReceivePort();
  late final StreamSubscription<StorageGetRequest> _getSubscription;
  late final StreamSubscription<StorageSetRequest> _setSubscription;
  late final StreamSubscription<StorageSetUncheckedRequest> _setUncheckedSubscription;
  late final StreamSubscription<StorageRemoveRequest> _removeSubscription;
  late final StreamSubscription<StorageRemoveUncheckedRequest> _removeUncheckedSubscription;
  final Future<String?> Function(String key) _get;
  final Future<void> Function({
    required String key,
    required String value,
  }) _set;
  final void Function({
    required String key,
    required String value,
  }) _setUnchecked;
  final Future<void> Function(String key) _remove;
  final void Function(String key) _removeUnchecked;

  Storage({
    required Future<String?> Function(String key) get,
    required Future<void> Function({
      required String key,
      required String value,
    })
        set,
    required void Function({
      required String key,
      required String value,
    })
        setUnchecked,
    required Future<void> Function(String key) remove,
    required void Function(String key) removeUnchecked,
  })  : _get = get,
        _set = set,
        _setUnchecked = setUnchecked,
        _remove = remove,
        _removeUnchecked = removeUnchecked {
    _getSubscription = _getPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = StorageGetRequest.fromJson(json);
      return payload;
    }).listen(_getRequestHandler);

    _setSubscription = _setPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = StorageSetRequest.fromJson(json);
      return payload;
    }).listen(_setRequestHandler);

    _setUncheckedSubscription = _setUncheckedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = StorageSetUncheckedRequest.fromJson(json);
      return payload;
    }).listen(_setUncheckedRequestHandler);

    _removeSubscription = _removePort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = StorageRemoveRequest.fromJson(json);
      return payload;
    }).listen(_removeRequestHandler);

    _removeUncheckedSubscription = _removeUncheckedPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = StorageRemoveUncheckedRequest.fromJson(json);
      return payload;
    }).listen(_removeUncheckedRequestHandler);

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

  Future<void> _getRequestHandler(StorageGetRequest event) async {
    final tx = toPtrFromAddress(event.tx);

    String? ok;
    String? err;

    try {
      ok = await _get(event.key);
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_optional_string(
          tx,
          ok?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _setRequestHandler(StorageSetRequest event) async {
    final tx = toPtrFromAddress(event.tx);

    String? err;

    try {
      await _set(
        key: event.key,
        value: event.value,
      );
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_unit(
          tx,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _setUncheckedRequestHandler(StorageSetUncheckedRequest event) async {
    try {
      _setUnchecked(
        key: event.key,
        value: event.value,
      );
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }

  Future<void> _removeRequestHandler(StorageRemoveRequest event) async {
    final tx = toPtrFromAddress(event.tx);

    String? err;

    try {
      await _remove(event.key);
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_unit(
          tx,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _removeUncheckedRequestHandler(StorageRemoveUncheckedRequest event) async {
    try {
      _removeUnchecked(event.key);
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }
}
