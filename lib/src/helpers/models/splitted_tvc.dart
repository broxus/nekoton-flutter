import 'package:freezed_annotation/freezed_annotation.dart';

part 'splitted_tvc.freezed.dart';
part 'splitted_tvc.g.dart';

@freezed
class SplittedTvc with _$SplittedTvc {
  @JsonSerializable()
  const factory SplittedTvc({
    String? data,
    String? code,
  }) = _SplittedTvc;

  factory SplittedTvc.fromJson(Map<String, dynamic> json) => _$SplittedTvcFromJson(json);
}
