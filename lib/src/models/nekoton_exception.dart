class NekotonException implements Exception {
  final String? info;

  NekotonException([this.info]);

  @override
  String toString() => info ?? super.toString();
}

class DynamicLibraryException extends NekotonException {
  DynamicLibraryException([String? info]) : super(info);
}

class TonWalletReadOnlyException extends NekotonException {
  TonWalletReadOnlyException([String? info]) : super(info);
}

class UnknownSignerException extends NekotonException {
  UnknownSignerException([String? info]) : super(info);
}
