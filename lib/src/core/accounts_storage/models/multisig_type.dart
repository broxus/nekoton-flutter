import 'package:json_annotation/json_annotation.dart';

enum MultisigType {
  @JsonValue('SafeMultisigWallet')
  safeMultisigWallet,
  @JsonValue('SafeMultisigWallet24h')
  safeMultisigWallet24h,
  @JsonValue('SetcodeMultisigWallet')
  setcodeMultisigWallet,
  @JsonValue('SurfWallet')
  surfWallet,
}
