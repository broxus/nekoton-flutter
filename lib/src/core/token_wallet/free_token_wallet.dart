part of 'token_wallet.dart';

void freeTokenWallet(TokenWallet tokenWallet) {
  tokenWallet._nativeLibrary.bindings.free_token_wallet(
    tokenWallet._nativeTokenWallet.ptr!,
  );
  tokenWallet._nativeTokenWallet.ptr = null;
  tokenWallet._receivePort.close();
  tokenWallet._subscription.cancel();
  tokenWallet._timer.cancel();
  tokenWallet._onBalanceChangedSubject.close();
  tokenWallet._onTransactionsFoundSubject.close();
}
