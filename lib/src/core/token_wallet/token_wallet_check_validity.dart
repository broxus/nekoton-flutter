part of 'token_wallet.dart';

Future<bool> tokenWalletCheckValidity({
  required GqlTransport transport,
  required String owner,
  required String rootTokenContract,
}) async {
  final nativeLibrary = NativeLibrary.instance();
  final receivePort = ReceivePort();

  try {
    final result = await proceedAsync((port) => nativeLibrary.bindings.token_wallet_subscribe(
          port,
          receivePort.sendPort.nativePort,
          transport.nativeGqlTransport.ptr!,
          owner.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeLibrary.bindings.free_token_wallet(ptr);

    return true;
  } catch (_) {
    return false;
  }
}
