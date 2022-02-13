import 'package:freezed_annotation/freezed_annotation.dart';

part 'keypair.freezed.dart';
part 'keypair.g.dart';

@freezed
class Keypair with _$Keypair {
  const factory Keypair({
    required String public,
    required String secret,
  }) = _Keypair;

  factory Keypair.fromJson(Map<String, dynamic> json) => _$KeypairFromJson(json);
}
