import 'nekoton_exception.dart';

abstract class NativeException extends NekotonException {
  NativeException([String? info]) : super(info);
}

class ConversionException extends NativeException {
  ConversionException([String? info]) : super(info);
}

class AccountsStorageException extends NativeException {
  AccountsStorageException([String? info]) : super(info);
}

class KeyStoreException extends NativeException {
  KeyStoreException([String? info]) : super(info);
}

class TokenWalletException extends NativeException {
  TokenWalletException([String? info]) : super(info);
}

class TonWalletException extends NativeException {
  TonWalletException([String? info]) : super(info);
}

class CryptoException extends NativeException {
  CryptoException([String? info]) : super(info);
}

class DePoolException extends NativeException {
  DePoolException([String? info]) : super(info);
}

class AbiException extends NativeException {
  AbiException([String? info]) : super(info);
}

class TransportException extends NativeException {
  TransportException([String? info]) : super(info);
}
