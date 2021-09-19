part of 'ton_wallet.dart';

Future<TonWallet> tonWalletSubscribe({
  required int workchain,
  required KeyStoreEntry entry,
  required WalletType walletType,
  Logger? logger,
}) async {
  final tonWallet = TonWallet._();

  tonWallet._logger = logger;

  tonWallet._transport = await GqlTransport.getInstance(logger: tonWallet._logger);
  tonWallet._keystore = await Keystore.getInstance(logger: tonWallet._logger);
  tonWallet._entry = entry;
  tonWallet._subscription = tonWallet._receivePort.listen(tonWallet._subscriptionListener);

  final walletTypeStr = jsonEncode(walletType.toJson());
  final result = await proceedAsync((port) => tonWallet._nativeLibrary.bindings.ton_wallet_subscribe(
        port,
        tonWallet._receivePort.sendPort.nativePort,
        tonWallet._transport.nativeGqlTransport.ptr!,
        workchain,
        entry.publicKey.toNativeUtf8().cast<Int8>(),
        walletTypeStr.toNativeUtf8().cast<Int8>(),
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
