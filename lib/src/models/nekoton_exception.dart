class NekotonException implements Exception {
  final String _message;

  NekotonException(this._message);

  @override
  String toString() => _message;
}
