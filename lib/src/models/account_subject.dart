import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../core/accounts_storage/models/assets_list.dart';

class AccountSubject implements Comparable<AccountSubject> {
  final BehaviorSubject<AssetsList> _behaviorSubject;

  AccountSubject(AssetsList assetsList) : _behaviorSubject = BehaviorSubject<AssetsList>.seeded(assetsList);

  AssetsList get value => _behaviorSubject.value;

  ValueStream<AssetsList> get stream => _behaviorSubject.stream;

  void add(AssetsList event) => _behaviorSubject.add(event);

  StreamSubscription<AssetsList> listen(
    void Function(AssetsList)? onData, {
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
  int compareTo(AccountSubject other) => _behaviorSubject.value.address.compareTo(other.value.address);
}
