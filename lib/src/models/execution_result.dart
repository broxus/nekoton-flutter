import 'dart:ffi';

import '../ffi_utils.dart';
import 'execution_status.dart';

class ExecutionResult extends Struct {
  @Uint32()
  external int statusCode;

  @Uint64()
  external int payload;
}

extension Handle on ExecutionResult {
  int handle() {
    final status = ExecutionStatus.values[statusCode];

    switch (status) {
      case ExecutionStatus.ok:
        return payload;
      case ExecutionStatus.err:
        throw Exception(cStringToDart(payload));
    }
  }
}
