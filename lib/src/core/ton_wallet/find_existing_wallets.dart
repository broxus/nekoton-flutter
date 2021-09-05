part of 'ton_wallet.dart';

Future<List<ExistingWalletInfo>> findExistingWallets({
  required String publicKey,
  required int workchainId,
}) async {
  final nativeLibrary = NativeLibrary.instance();
  final gql = await Gql.getInstance();

  final result = await proceedAsync((port) => nativeLibrary.bindings.find_existing_wallets(
        port,
        gql.nativeTransport.ptr!,
        publicKey.toNativeUtf8().cast<Int8>(),
        workchainId,
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final jsonList = json.cast<Map<String, dynamic>>();
  final existingWallets = jsonList.map((e) => ExistingWalletInfo.fromJson(e)).toList();

  return existingWallets;
}
