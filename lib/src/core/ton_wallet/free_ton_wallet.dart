part of 'ton_wallet.dart';

void freeTonWallet(TonWallet tonWallet) {
  nativeLibraryInstance.bindings.free_ton_wallet(
    tonWallet.nativeTonWallet.ptr!,
  );
  tonWallet.nativeTonWallet.ptr = null;
  tonWallet._receivePort.close();
  tonWallet._subscription.cancel();
  tonWallet._timer.cancel();
  tonWallet._onMessageSentSubject.close();
  tonWallet._onMessageExpiredSubject.close();
  tonWallet._onStateChangedSubject.close();
  tonWallet._onTransactionsFoundSubject.close();
}
