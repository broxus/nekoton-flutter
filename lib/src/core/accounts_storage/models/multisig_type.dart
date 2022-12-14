import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.pascal)
enum MultisigType {
  safeMultisigWallet,
  safeMultisigWallet24h,
  setcodeMultisigWallet,
  setcodeMultisigWallet24h,
  bridgeMultisigWallet,
  surfWallet,
  multisig2,
  multisig2_1,
}
