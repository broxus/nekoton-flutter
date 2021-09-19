part of 'ton_wallet.dart';

Future<TonWallet> tonWalletSubscribeByAddress({
  required String address,
  Logger? logger,
}) async {
  final tonWallet = TonWallet._();

  tonWallet._logger = logger;

  tonWallet._transport = await GqlTransport.getInstance(logger: tonWallet._logger);
  tonWallet._subscription = tonWallet._receivePort.listen(tonWallet._subscriptionListener);

  final result = await proceedAsync((port) => tonWallet._nativeLibrary.bindings.ton_wallet_subscribe_by_address(
        port,
        tonWallet._receivePort.sendPort.nativePort,
        tonWallet._transport.nativeGqlTransport.ptr!,
        address.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  tonWallet.nativeTonWallet = NativeTonWallet(ptr);
  tonWallet._timer = Timer.periodic(
    const Duration(seconds: 15),
    tonWallet._refreshTimer,
  );
  tonWallet.address = await tonWallet._address;
  tonWallet.publicKey = await tonWallet._publicKey;
  tonWallet.walletType = await tonWallet._walletType;
  tonWallet.details = await tonWallet._details;
  tonWallet.custodians = await tonWallet._custodians;

  return tonWallet;
}
