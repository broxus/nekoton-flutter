import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/ledger_signature_context.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:tuple/tuple.dart';

typedef LedgerConnectionGetPublicKey = Future<String> Function(int accountId);

typedef LedgerConnectionSign = Future<String> Function({
  required int account,
  required List<int> message,
  LedgerSignatureContext? context,
});

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_ledger_connection_free_ptr);

class LedgerConnection implements Finalizable {
  late final Pointer<Void> _ptr;
  final _getPublicKeyPort = ReceivePort();
  final _signPort = ReceivePort();
  late final StreamSubscription<Tuple2<String, int>> _getPublicKeySubscription;
  late final StreamSubscription<Tuple4<String, int, List<int>, LedgerSignatureContext?>>
      _signSubscription;
  final LedgerConnectionGetPublicKey _getPublicKey;
  final LedgerConnectionSign _sign;

  LedgerConnection({
    required LedgerConnectionGetPublicKey getPublicKey,
    required LedgerConnectionSign sign,
  })  : _getPublicKey = getPublicKey,
        _sign = sign {
    _getPublicKeySubscription = _getPublicKeyPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final tx = json.first as String;
      final accountId = json.last as int;

      return Tuple2(tx, accountId);
    }).listen(_getPublicKeyRequestHandler);

    _signSubscription = _signPort.cast<String>().map((e) {
      final json = jsonDecode(e) as List<dynamic>;

      final tx = json.first as String;
      final account = json[1] as int;
      final messageJson = json[2] as List<dynamic>;
      final message = messageJson.cast<int>();
      final contextJson = json.last as Map<String, dynamic>?;
      final context = contextJson != null ? LedgerSignatureContext.fromJson(contextJson) : null;

      return Tuple4(
        tx,
        account,
        message,
        context,
      );
    }).listen(_signRequestHandler);

    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_ledger_connection_create(
            _getPublicKeyPort.sendPort.nativePort,
            _signPort.sendPort.nativePort,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);
  }

  Pointer<Void> get ptr => _ptr;

  Future<void> dispose() async {
    await _getPublicKeySubscription.cancel();
    await _signSubscription.cancel();

    _getPublicKeyPort.close();
    _signPort.close();
  }

  Future<void> _getPublicKeyRequestHandler(Tuple2<String, int> event) async {
    final tx = toPtrFromAddress(event.item1);

    String? ok;
    String? err;

    try {
      ok = await _getPublicKey(event.item2);
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_string(
          tx,
          ok?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _signRequestHandler(
    Tuple4<String, int, List<int>, LedgerSignatureContext?> event,
  ) async {
    final tx = toPtrFromAddress(event.item1);

    String? ok;
    String? err;

    try {
      ok = await _sign(
        account: event.item2,
        message: event.item3,
        context: event.item4,
      );
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_string(
          tx,
          ok?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }
}
