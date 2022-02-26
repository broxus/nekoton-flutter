import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_accounts_by_code_hash_output.freezed.dart';
part 'get_accounts_by_code_hash_output.g.dart';

@freezed
class GetAccountsByCodeHashOutput with _$GetAccountsByCodeHashOutput {
  const factory GetAccountsByCodeHashOutput({
    required List<String> accounts,
    @JsonKey(includeIfNull: false) String? continuation,
  }) = _GetAccountsByCodeHashOutput;

  factory GetAccountsByCodeHashOutput.fromJson(Map<String, dynamic> json) =>
      _$GetAccountsByCodeHashOutputFromJson(json);
}
