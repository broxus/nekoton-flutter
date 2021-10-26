class NekotonException implements Exception {
  final String? info;

  NekotonException([this.info]);

  @override
  String toString() => info ?? super.toString();
}

class DynamicLibraryException extends NekotonException {
  DynamicLibraryException([String? info]) : super(info);
}

class IncorrectDataFormatException extends NekotonException {
  IncorrectDataFormatException([String? info]) : super(info);
}

class PermissionsNotGrantedException extends NekotonException {
  PermissionsNotGrantedException([String? info]) : super(info);
}

class KeystoreNotFoundException extends NekotonException {
  KeystoreNotFoundException([String? info]) : super(info);
}

class UnsignedMessageNotFoundException extends NekotonException {
  UnsignedMessageNotFoundException([String? info]) : super(info);
}

class AccountStorageNotFoundException extends NekotonException {
  AccountStorageNotFoundException([String? info]) : super(info);
}

class TokenWalletNotFoundException extends NekotonException {
  TokenWalletNotFoundException([String? info]) : super(info);
}

class TonWalletNotFoundException extends NekotonException {
  TonWalletNotFoundException([String? info]) : super(info);
}

class GenericContractNotFoundException extends NekotonException {
  GenericContractNotFoundException([String? info]) : super(info);
}

class GqlConnectionNotFoundException extends NekotonException {
  GqlConnectionNotFoundException([String? info]) : super(info);
}

class GqlTransportNotFoundException extends NekotonException {
  GqlTransportNotFoundException([String? info]) : super(info);
}

class StorageNotFoundException extends NekotonException {
  StorageNotFoundException([String? info]) : super(info);
}

class TransactionTimeoutException extends NekotonException {
  TransactionTimeoutException([String? info]) : super(info);
}

class TransactionNotFoundException extends NekotonException {
  TransactionNotFoundException([String? info]) : super(info);
}

class AccountNotFoundException extends NekotonException {
  AccountNotFoundException([String? info]) : super(info);
}

class AccountNotDeployedException extends NekotonException {
  AccountNotDeployedException([String? info]) : super(info);
}

class TonWalletReadOnlyException extends NekotonException {
  TonWalletReadOnlyException([String? info]) : super(info);
}

class GenericContractReadOnlyException extends NekotonException {
  GenericContractReadOnlyException([String? info]) : super(info);
}

class UnknownSignerException extends NekotonException {
  UnknownSignerException([String? info]) : super(info);
}

class InvalidRootTokenContractException extends NekotonException {
  InvalidRootTokenContractException([String? info]) : super(info);
}

class InvalidAddressException extends NekotonException {
  InvalidAddressException([String? info]) : super(info);
}
