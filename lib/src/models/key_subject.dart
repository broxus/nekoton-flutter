import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../core/keystore/models/key_store_entry.dart';

class KeySubject implements Comparable<KeySubject> {
  final BehaviorSubject<KeyStoreEntry> _behaviorSubject;

  KeySubject(KeyStoreEntry assetsList) : _behaviorSubject = BehaviorSubject<KeyStoreEntry>.seeded(assetsList);

  KeyStoreEntry get value => _behaviorSubject.value;

  ValueStream<KeyStoreEntry> get stream => _behaviorSubject.stream;

  void add(KeyStoreEntry event) => _behaviorSubject.add(event);

  StreamSubscription<KeyStoreEntry> listen(
    void Function(KeyStoreEntry)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _behaviorSubject.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  int compareTo(KeySubject other) => _behaviorSubject.value.publicKey.compareTo(other.value.publicKey);
}
