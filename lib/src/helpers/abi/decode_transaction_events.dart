import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/decoded_transaction_event.dart';

List<DecodedTransactionEvent> decodeTransactionEvents({
  required Transaction transaction,
  required String contractAbi,
}) {
  final transactionStr = jsonEncode(transaction);

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_decode_transaction_events(
          transactionStr.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
        ),
  );

  final json = result as List<dynamic>;
  final list = json.cast<Map<String, dynamic>>();
  final decodedTransactionEvents = list.map((e) => DecodedTransactionEvent.fromJson(e)).toList();

  return decodedTransactionEvents;
}
