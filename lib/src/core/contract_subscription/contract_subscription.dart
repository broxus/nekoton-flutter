import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/core/contract_subscription/constants.dart';
import 'package:nekoton_flutter/src/core/models/pending_transaction.dart';
import 'package:nekoton_flutter/src/core/models/polling_method.dart';
import 'package:nekoton_flutter/src/transport/gql_transport.dart';
import 'package:nekoton_flutter/src/transport/jrpc_transport.dart';
import 'package:nekoton_flutter/src/transport/transport.dart';

abstract class ContractSubscription {
  Transport get transport;

  String get address;

  Future<PollingMethod> get pollingMethod;

  Future<void> refresh();

  Future<void> handleBlock(String block);

  @protected
  Future<PendingTransaction> sendWithReliablePolling(
    Future<PendingTransaction> Function() send,
  ) async {
    final transport = this.transport;

    if (transport is GqlTransport) {
      var currentBlockId = await transport.getLatestBlockId(address);

      final pendingTransaction = await send();

      () async {
        while (await pollingMethod == PollingMethod.reliable) {
          try {
            final nextBlockId = await transport.waitForNextBlockId(
              currentBlockId: currentBlockId,
              address: address,
              timeout: kNextBlockTimeout.inSeconds,
            );

            final block = await transport.getBlock(nextBlockId);

            await handleBlock(block);

            currentBlockId = nextBlockId;
          } catch (_) {
            break;
          }
        }
      }();

      return pendingTransaction;
    } else if (transport is JrpcTransport) {
      final pendingTransaction = await send();

      () async {
        while (await pollingMethod == PollingMethod.reliable) {
          try {
            await Future<void>.delayed(kIntensivePollingInterval);
            await refresh();
          } catch (_) {
            break;
          }
        }
      }();

      return pendingTransaction;
    } else {
      throw UnsupportedError('Invalid transport');
    }
  }
}
