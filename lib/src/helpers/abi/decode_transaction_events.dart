import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../core/models/transaction.dart';
import '../../ffi_utils.dart';
import 'models/decoded_transaction_event.dart';

List<DecodedTransactionEvent> decodeTransactionEvents({
  required Transaction transaction,
  required String contractAbi,
}) {
  final transactionStr = jsonEncode(transaction);

  final result = executeSync(
    () => NekotonFlutter.bindings.nt_decode_transaction_events(
      transactionStr.toNativeUtf8().cast<Char>(),
      contractAbi.toNativeUtf8().cast<Char>(),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as List<dynamic>;
  final list = json.cast<Map<String, dynamic>>();
  final decodedTransactionEvents = list.map((e) => DecodedTransactionEvent.fromJson(e)).toList();

  return decodedTransactionEvents;
}
