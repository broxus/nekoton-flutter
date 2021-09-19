part of 'token_wallet.dart';

Future<TokenWallet> tokenWalletSubscribe({
  required TonWallet tonWallet,
  required String rootTokenContract,
  Logger? logger,
}) async {
  final tokenWallet = TokenWallet._();

  tokenWallet._logger = logger;

  tokenWallet._tonWallet = tonWallet;
  tokenWallet._subscription = tokenWallet._receivePort.listen(tokenWallet._subscriptionListener);
  tokenWallet._transport = await GqlTransport.getInstance(logger: tokenWallet._logger);

  final tonWalletAddress = tokenWallet._tonWallet.address;
  final result = await proceedAsync((port) => tokenWallet._nativeLibrary.bindings.token_wallet_subscribe(
        port,
        tokenWallet._receivePort.sendPort.nativePort,
        tokenWallet._transport.nativeGqlTransport.ptr!,
        tonWalletAddress.toNativeUtf8().cast<Int8>(),
        rootTokenContract.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  tokenWallet._nativeTokenWallet = NativeTokenWallet(ptr);
  tokenWallet._timer = Timer.periodic(
    const Duration(seconds: 15),
    tokenWallet._refreshTimer,
  );
  tokenWallet.owner = await tokenWallet._owner;
  tokenWallet.address = await tokenWallet._address;
  tokenWallet.symbol = await tokenWallet._symbol;
  tokenWallet.version = await tokenWallet._version;
  tokenWallet.ownerPublicKey = tonWallet.publicKey;

  return tokenWallet;
}
