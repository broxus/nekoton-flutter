import 'package:freezed_annotation/freezed_annotation.dart';

import 'abi_param.dart';

part 'pack_into_cell_input.freezed.dart';
part 'pack_into_cell_input.g.dart';

@freezed
class PackIntoCellInput with _$PackIntoCellInput {
  @JsonSerializable(explicitToJson: true)
  const factory PackIntoCellInput({
    required List<AbiParam> structure,
    required Map<String, dynamic> data,
  }) = _PackIntoCellInput;

  factory PackIntoCellInput.fromJson(Map<String, dynamic> json) => _$PackIntoCellInputFromJson(json);
}
