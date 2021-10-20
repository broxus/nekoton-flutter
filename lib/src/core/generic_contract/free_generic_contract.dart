part of 'generic_contract.dart';

void freeGenericContract(GenericContract genericContract) {
  nativeLibraryInstance.bindings.free_generic_contract(
    genericContract._nativeGenericContract.ptr!,
  );
  genericContract._nativeGenericContract.ptr = null;
  genericContract._receivePort.close();
  genericContract._subscription.cancel();
  genericContract._timer.cancel();
  genericContract._onMessageSentSubject.close();
  genericContract._onMessageExpiredSubject.close();
  genericContract._onStateChangedSubject.close();
  genericContract._onTransactionsFoundSubject.close();
}
