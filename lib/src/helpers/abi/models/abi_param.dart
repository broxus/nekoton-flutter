import 'package:freezed_annotation/freezed_annotation.dart';

part 'abi_param.freezed.dart';
part 'abi_param.g.dart';

@freezed
class AbiParam with _$AbiParam {
  const factory AbiParam({
    required String name,
    required String type,
    List<AbiParam>? components,
  }) = _AbiParam;

  factory AbiParam.fromJson(Map<String, dynamic> json) => _$AbiParamFromJson(json);
}
