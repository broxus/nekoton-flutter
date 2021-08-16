import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../core/models/account_subscription.dart';

class SubscriptionSubject implements Comparable<SubscriptionSubject> {
  final BehaviorSubject<AccountSubscription> _behaviorSubject;

  SubscriptionSubject(AccountSubscription assetsList)
      : _behaviorSubject = BehaviorSubject<AccountSubscription>.seeded(assetsList);

  AccountSubscription get value => _behaviorSubject.value;

  ValueStream<AccountSubscription> get stream => _behaviorSubject.stream;

  void add(AccountSubscription event) => _behaviorSubject.add(event);

  StreamSubscription<AccountSubscription> listen(
    void Function(AccountSubscription)? onData, {
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
  int compareTo(SubscriptionSubject other) => _behaviorSubject.value.address.compareTo(other.value.address);
}
