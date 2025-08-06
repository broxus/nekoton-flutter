import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_type.g.dart';

@JsonEnum(alwaysCreate: true)
enum TransportType {
  jrpc,
  gql,
  proto;

  @override
  String toString() => _$TransportTypeEnumMap[this]!;
}
