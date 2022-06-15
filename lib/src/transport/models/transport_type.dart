import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_type.g.dart';

@JsonEnum(alwaysCreate: true)
enum TransportType {
  jrpc,
  gql;

  @override
  String toString() => _$TransportTypeEnumMap[this]!;
}
