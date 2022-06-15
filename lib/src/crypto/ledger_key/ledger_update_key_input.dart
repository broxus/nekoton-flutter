import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/update_key_input.dart';
import 'ledger_update_key_input_rename.dart';

part 'ledger_update_key_input.freezed.dart';
part 'ledger_update_key_input.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class LedgerUpdateKeyInput with _$LedgerUpdateKeyInput implements UpdateKeyInput {
  const factory LedgerUpdateKeyInput.rename(LedgerUpdateKeyInputRename data) = _LedgerUpdateKeyInputRename;

  factory LedgerUpdateKeyInput.fromJson(Map<String, dynamic> json) => _$LedgerUpdateKeyInputFromJson(json);
}
