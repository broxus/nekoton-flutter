import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';

import '../../transport/gql_transport.dart';
import '../../transport/models/transport_type.dart';
import '../../transport/transport.dart';
import '../models/polling_method.dart';
import 'constants.dart';

abstract class ContractSubscription {
  abstract final Transport transport;
  Future<void>? _loopFuture;
  CancelableCompleter? _refreshCompleter;
  Duration _pollingInterval = kDefaultPollingInterval;
  PollingMethod? _currentPollingMethod;
  bool _isRunning = false;
  String? _currentBlockId;
  String? _suggestedBlockId;

  Future<String> get address;

  Future<PollingMethod> get pollingMethod;

  Future<void> refresh();

  Future<void> handleBlock(String block);

  void setPollingInterval(Duration interval) {
    skipRefreshTimer();
    _pollingInterval = interval;
  }

  @protected
  Future<void> startPolling() async {
    await _loopFuture;

    _loopFuture = Future(() async {
      final isSimpleTransport = transport.type != TransportType.gql;

      _isRunning = true;

      var previousPollingMethod = _currentPollingMethod;

      while (_isRunning) {
        final pollingMethodChanged = previousPollingMethod != _currentPollingMethod;
        previousPollingMethod = _currentPollingMethod;

        if (isSimpleTransport || _currentPollingMethod == PollingMethod.manual) {
          _currentBlockId = null;

          final currentPollingInterval =
              _currentPollingMethod == PollingMethod.manual ? _pollingInterval : kIntensivePollingInterval;

          final refreshCompleter = CancelableCompleter<void>();
          _refreshCompleter = refreshCompleter;
          Future.delayed(currentPollingInterval, () async {
            if (!refreshCompleter.isCanceled && !refreshCompleter.isCompleted) refreshCompleter.complete();
          });
          await refreshCompleter.operation.valueOrCancellation();

          if (!_isRunning) break;

          try {
            await refresh();
            _currentPollingMethod = await pollingMethod;
          } catch (err, st) {
            debugPrint(err.toString());
            debugPrint(st.toString());
          }
        } else {
          final transport = this.transport as GqlTransport;

          if (pollingMethodChanged && _suggestedBlockId != null) {
            _currentBlockId = _suggestedBlockId;
          }
          _suggestedBlockId = null;

          String nextBlockId;
          if (_currentBlockId == null) {
            try {
              _currentBlockId = await transport.getLatestBlockId(await address);
              nextBlockId = _currentBlockId!;
            } catch (err, st) {
              debugPrint(err.toString());
              debugPrint(st.toString());
              continue;
            }
          } else {
            try {
              nextBlockId = await transport.waitForNextBlockId(
                currentBlockId: _currentBlockId!,
                address: await address,
                timeout: kNextBlockTimeout.inSeconds,
              );
            } catch (err, st) {
              debugPrint(err.toString());
              debugPrint(st.toString());
              continue;
            }
          }

          try {
            final block = await transport.getBlock(nextBlockId);
            await handleBlock(block);
            _currentPollingMethod = await pollingMethod;
            _currentBlockId = nextBlockId;
          } catch (err, st) {
            debugPrint(err.toString());
            debugPrint(st.toString());
          }
        }
      }
    });
  }

  @protected
  void skipRefreshTimer() {
    _refreshCompleter?.operation.cancel();
    _refreshCompleter = null;
  }

  @protected
  Future<void> pausePolling() async {
    if (!_isRunning) return;

    _isRunning = false;

    skipRefreshTimer();

    await _loopFuture;
    _loopFuture = null;

    _currentPollingMethod = await pollingMethod;

    _currentBlockId = null;
    _suggestedBlockId = null;
  }

  @protected
  Future<void> prepareReliablePolling() async {
    try {
      if (transport.type == TransportType.gql) {
        final transport = this.transport as GqlTransport;
        _suggestedBlockId = await transport.getLatestBlockId(await address);
      }
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrint(st.toString());
    }
  }
}
