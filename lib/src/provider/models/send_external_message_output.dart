import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/models/transaction.dart';

part 'send_external_message_output.freezed.dart';
part 'send_external_message_output.g.dart';

@freezed
class SendExternalMessageOutput with _$SendExternalMessageOutput {
  @JsonSerializable()
  const factory SendExternalMessageOutput({
    required Transaction transaction,
    required Map<String, dynamic>? output,
  }) = _SendExternalMessageOutput;

  factory SendExternalMessageOutput.fromJson(Map<String, dynamic> json) => _$SendExternalMessageOutputFromJson(json);
}
