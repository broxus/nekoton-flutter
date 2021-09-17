part of 'generic_contract.dart';

Future<GenericContract> genericContractSubscribe({
  required String address,
  KeyStoreEntry? entry,
  Logger? logger,
}) async {
  final genericContract = GenericContract._();

  genericContract._logger = logger;

  genericContract._gql = await Gql.getInstance(logger: genericContract._logger);
  genericContract._keystore = await Keystore.getInstance(logger: genericContract._logger);
  genericContract._entry = entry;
  genericContract._subscription = genericContract._receivePort.listen(genericContract._subscriptionListener);

  final result = await proceedAsync((port) => genericContract._nativeLibrary.bindings.generic_contract_subscribe(
        port,
        genericContract._receivePort.sendPort.nativePort,
        genericContract._gql.nativeTransport.ptr!,
        address.toNativeUtf8().cast<Int8>(),
      ));
  final ptr = Pointer.fromAddress(result).cast<Void>();

  genericContract._nativeGenericContract = NativeGenericContract(ptr);
  genericContract._timer = Timer.periodic(
    const Duration(seconds: 15),
    genericContract._refreshTimer,
  );
  genericContract.address = await genericContract._address;

  return genericContract;
}
