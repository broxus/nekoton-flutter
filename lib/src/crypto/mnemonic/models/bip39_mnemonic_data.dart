import 'package:freezed_annotation/freezed_annotation.dart';

part 'bip39_mnemonic_data.freezed.dart';
part 'bip39_mnemonic_data.g.dart';

enum Bip39Entropy {
  bits128,
  bits256,
}

enum Bip39Path {
  ever,
  ton,
}

@freezed
abstract class Bip39MnemonicData with _$Bip39MnemonicData {
  const factory Bip39MnemonicData({
    @JsonKey(name: 'account_id') required int accountId,
    required Bip39Path path,
    required Bip39Entropy entropy,
  }) = _Bip39MnemonicData;

  factory Bip39MnemonicData.fromJson(Map<String, dynamic> json) =>
      _$Bip39MnemonicDataFromJson(json);
}
