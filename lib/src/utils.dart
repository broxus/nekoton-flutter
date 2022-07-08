import 'package:rxdart/rxdart.dart';

extension SubjectTryAdd<T> on Subject<T> {
  void tryAdd(T event) {
    if (!isClosed) add(event);
  }
}
