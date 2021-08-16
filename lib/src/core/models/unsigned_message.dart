import 'package:freezed_annotation/freezed_annotation.dart';

import 'native_unsigned_message.dart';

part 'unsigned_message.freezed.dart';

@freezed
class UnsignedMessage with _$UnsignedMessage {
  const factory UnsignedMessage(NativeUnsignedMessage nativeUnsignedMessage) = _UnsignedMessage;
}
