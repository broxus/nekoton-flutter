import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_expected_address_input.freezed.dart';
part 'get_expected_address_input.g.dart';

@freezed
class GetExpectedAddressInput with _$GetExpectedAddressInput {
  @JsonSerializable()
  const factory GetExpectedAddressInput({
    required String tvc,
    required String abi,
    int? workchain,
    String? publicKey,
    required Map<String, dynamic> initParams,
  }) = _GetExpectedAddressInput;

  factory GetExpectedAddressInput.fromJson(Map<String, dynamic> json) => _$GetExpectedAddressInputFromJson(json);
}
