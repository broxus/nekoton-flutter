import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointed.dart';
import 'models/storage_get_request.dart';
import 'models/storage_remove_request.dart';
import 'models/storage_remove_unchecked_request.dart';
import 'models/storage_set_request.dart';
import 'models/storage_set_unchecked_request.dart';

class Storage implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;
  final _getPort = ReceivePort();
  final _setPort = ReceivePort();
  final _setUncheckedPort = ReceivePort();
  final _removePort = ReceivePort();
  final _removeUncheckedPort = ReceivePort();
  late final StreamSubscription _getSubscription;
  late final StreamSubscription _setSubscription;
  late final StreamSubscription _setUncheckedSubscription;
  late final StreamSubscription _removeSubscription;
  late final StreamSubscription _removeUncheckedSubscription;
  final Future<String?> Function(String key) get;
  final Future<void> Function({
    required String key,
    required String value,
  }) set;
  final void Function({
    required String key,
    required String value,
  }) setUnchecked;
  final Future<void> Function(String key) remove;
  final void Function(String key) removeUnchecked;

  Storage({
    required this.get,
    required this.set,
    required this.setUnchecked,
    required this.remove,
    required this.removeUnchecked,
  }) {
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

    _ptr = Pointer.fromAddress(result as int).cast<Void>();
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Storage use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_storage_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() async {
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

        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_storage_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

  Future<void> _getRequestHandler(StorageGetRequest event) async {
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? ok;
    String? err;

    try {
      ok = await get(event.key);
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
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? err;

    try {
      await set(
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
      setUnchecked(
        key: event.key,
        value: event.value,
      );
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }

  Future<void> _removeRequestHandler(StorageRemoveRequest event) async {
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? err;

    try {
      await remove(event.key);
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
      removeUnchecked(event.key);
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }
}
