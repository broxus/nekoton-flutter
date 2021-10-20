part of 'generic_contract.dart';

Future<GenericContract> genericContractSubscribe({
  required GqlTransport transport,
  required String address,
}) async {
  final genericContract = GenericContract._();

  genericContract._transport = transport;
  genericContract._keystore = await Keystore.getInstance();
  genericContract._subscription = genericContract._receivePort.listen(genericContract._subscriptionListener);

  final result = await proceedAsync((port) => nativeLibraryInstance.bindings.generic_contract_subscribe(
        port,
        genericContract._receivePort.sendPort.nativePort,
        genericContract._transport.nativeGqlTransport.ptr!,
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
