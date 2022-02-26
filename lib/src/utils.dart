import 'dart:async';

class CustomRestartableTimer implements Timer {
  final ZoneCallback _callback;
  Timer _timer;

  CustomRestartableTimer(Duration initialDuration, this._callback) : _timer = Timer(initialDuration, _callback);

  @override
  bool get isActive => _timer.isActive;

  void reset(Duration duration) {
    _timer.cancel();
    _timer = Timer(duration, _callback);
  }

  @override
  void cancel() => _timer.cancel();

  @override
  int get tick => _timer.tick;
}
