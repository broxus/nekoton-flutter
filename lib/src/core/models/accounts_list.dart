import 'package:freezed_annotation/freezed_annotation.dart';

part 'accounts_list.freezed.dart';
part 'accounts_list.g.dart';

@freezed
class AccountsList with _$AccountsList {
  const factory AccountsList({
    required List<String> accounts,
    @JsonKey(includeIfNull: false) String? continuation,
  }) = _AccountsList;

  factory AccountsList.fromJson(Map<String, dynamic> json) => _$AccountsListFromJson(json);
}
