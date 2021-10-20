part of 'token_wallet.dart';

Future<bool> tokenWalletCheckValidity({
  required GqlTransport transport,
  required String owner,
  required String rootTokenContract,
}) async {
  final receivePort = ReceivePort();

  try {
    final result = await proceedAsync((port) => nativeLibraryInstance.bindings.token_wallet_subscribe(
          port,
          receivePort.sendPort.nativePort,
          transport.nativeGqlTransport.ptr!,
          owner.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    nativeLibraryInstance.bindings.free_token_wallet(ptr);

    return true;
  } catch (_) {
    return false;
  }
}
