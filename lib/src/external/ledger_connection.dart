import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../ffi_utils.dart';
import '../models/pointer_wrapper.dart';
import 'models/ledger_connection_get_public_key_request.dart';
import 'models/ledger_connection_sign_request.dart';
import 'models/ledger_signature_context.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_ledger_connection_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class LedgerConnection {
  late final PointerWrapper pointerWrapper;
  final _getPublicKeyPort = ReceivePort();
  final _signPort = ReceivePort();
  late final StreamSubscription _getPublicKeySubscription;
  late final StreamSubscription _signSubscription;
  final Future<String> Function(int accountId) getPublicKey;
  final Future<String> Function({
    required int account,
    required List<int> message,
    LedgerSignatureContext? context,
  }) sign;

  LedgerConnection({
    required this.getPublicKey,
    required this.sign,
  }) {
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

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);
  }

  Future<void> dispose() async {
    await _getPublicKeySubscription.cancel();
    await _signSubscription.cancel();

    _getPublicKeyPort.close();
    _signPort.close();
  }

  Future<void> _getPublicKeyRequestHandler(LedgerConnectionGetPublicKeyRequest event) async {
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? ok;
    String? err;

    try {
      ok = await getPublicKey(event.accountId);
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
    final tx = Pointer.fromAddress(event.tx).cast<Void>();

    String? ok;
    String? err;

    try {
      ok = await sign(
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
