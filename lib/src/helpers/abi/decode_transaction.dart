import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../core/models/transaction.dart';
import '../../ffi_utils.dart';
import 'models/decoded_transaction.dart';
import 'models/method_name.dart';

DecodedTransaction? decodeTransaction({
  required Transaction transaction,
  required String contractAbi,
  required MethodName method,
}) {
  final transactionStr = jsonEncode(transaction);
  final methodStr = method != null ? jsonEncode(method) : null;

  final result = executeSync(
    () => NekotonFlutter.instance().bindings.nt_decode_transaction(
          transactionStr.toNativeUtf8().cast<Char>(),
          contractAbi.toNativeUtf8().cast<Char>(),
          methodStr?.toNativeUtf8().cast<Char>() ?? nullptr,
        ),
  );

  final json = result != null ? result as Map<String, dynamic> : null;
  final decodedTransaction = json != null ? DecodedTransaction.fromJson(json) : null;

  return decodedTransaction;
}
