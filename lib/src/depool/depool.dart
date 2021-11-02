import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../connection_controller.dart';
import '../ffi_utils.dart';
import '../nekoton.dart';
import '../transport/gql_transport.dart';
import 'models/depool_info.dart';
import 'models/participant_info.dart';

Future<ParticipantInfo> getParticipantInfo({
  required String address,
  required String walletAddress,
}) async {
  final connectionController = await ConnectionController.getInstance();
  final transport = connectionController.transport as GqlTransport;

  final result = await transport.nativeGqlTransport.use(
    (ptr) => proceedAsync(
      (port) => nativeLibraryInstance.bindings.get_participant_info(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
        walletAddress.toNativeUtf8().cast<Int8>(),
      ),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final participantInfo = ParticipantInfo.fromJson(json);

  return participantInfo;
}

Future<DePoolInfo> getDePoolInfo(String address) async {
  final connectionController = await ConnectionController.getInstance();
  final transport = connectionController.transport as GqlTransport;

  final result = await transport.nativeGqlTransport.use(
    (ptr) => proceedAsync(
      (port) => nativeLibraryInstance.bindings.get_depool_info(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
      ),
    ),
  );

  final string = cStringToDart(result);
  final json = jsonDecode(string) as Map<String, dynamic>;
  final dePoolInfo = DePoolInfo.fromJson(json);

  return dePoolInfo;
}
