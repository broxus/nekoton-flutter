extension ExpireAtToTimeout on int {
  Duration toTimeout() =>
      DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(this * 1000));
}
