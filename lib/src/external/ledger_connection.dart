import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/external/models/ledger_connection_get_public_key_request.dart';
import 'package:nekoton_flutter/src/external/models/ledger_connection_sign_request.dart';
import 'package:nekoton_flutter/src/external/models/ledger_signature_context.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_ledger_connection_free_ptr);

class LedgerConnection implements Finalizable {
  late final Pointer<Void> _ptr;
  final _getPublicKeyPort = ReceivePort();
  final _signPort = ReceivePort();
  late final StreamSubscription<LedgerConnectionGetPublicKeyRequest> _getPublicKeySubscription;
  late final StreamSubscription<LedgerConnectionSignRequest> _signSubscription;
  final Future<String> Function(int accountId) _getPublicKey;
  final Future<String> Function({
    required int account,
    required List<int> message,
    LedgerSignatureContext? context,
  }) _sign;

  LedgerConnection({
    required Future<String> Function(int accountId) getPublicKey,
    required Future<String> Function({
      required int account,
      required List<int> message,
      LedgerSignatureContext? context,
    })
        sign,
  })  : _getPublicKey = getPublicKey,
        _sign = sign {
    _getPublicKeySubscription = _getPublicKeyPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = LedgerConnectionGetPublicKeyRequest.fromJson(json);
      return payload;
    }).listen(_getPublicKeyRequestHandler);

    _signSubscription = _signPort.cast<String>().map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      final payload = LedgerConnectionSignRequest.fromJson(json);
      return payload;
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

  Future<void> _getPublicKeyRequestHandler(LedgerConnectionGetPublicKeyRequest event) async {
    final tx = toPtrFromAddress(event.tx);

    String? ok;
    String? err;

    try {
      ok = await _getPublicKey(event.accountId);
    } catch (error) {
      err = error.toString();
    }

    NekotonFlutter.instance().bindings.nt_external_resolve_request_with_string(
          tx,
          ok?.toNativeUtf8().cast<Char>() ?? nullptr,
          err?.toNativeUtf8().cast<Char>() ?? nullptr,
        );
  }

  Future<void> _signRequestHandler(LedgerConnectionSignRequest event) async {
    final tx = toPtrFromAddress(event.tx);

    String? ok;
    String? err;

    try {
      ok = await _sign(
        account: event.account,
        message: event.message,
        context: event.context,
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
