import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import '../external/gql.dart';

import '../ffi_utils.dart';
import '../native_library.dart';
import 'models/depool_info.dart';
import 'models/participant_info.dart';

Future<ParticipantInfo> getParticipantInfo({
  required String address,
  required String walletAddress,
}) async {
  final transport = await Gql.getInstance();

  final nativeLibrary = NativeLibrary.instance();
  final result = await proceedAsync((port) => nativeLibrary.bindings.get_participant_info(
        port,
        transport.nativeTransport.ptr!,
        address.toNativeUtf8().cast<Int8>(),
        walletAddress.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final participantInfo = ParticipantInfo.fromJson(json);

  return participantInfo;
}

Future<DePoolInfo> getDePoolInfo(String address) async {
  final transport = await Gql.getInstance();

  final nativeLibrary = NativeLibrary.instance();
  final result = await proceedAsync((port) => nativeLibrary.bindings.get_depool_info(
        port,
        transport.nativeTransport.ptr!,
        address.toNativeUtf8().cast<Int8>(),
      ));

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final dePoolInfo = DePoolInfo.fromJson(json);

  return dePoolInfo;
}
