import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/models/transaction.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/decoded_transaction.dart';
import 'package:nekoton_flutter/src/helpers/abi/models/method_name.dart';

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

  final json = result as Map<String, dynamic>?;
  final decodedTransaction = json != null ? DecodedTransaction.fromJson(json) : null;

  return decodedTransaction;
}
