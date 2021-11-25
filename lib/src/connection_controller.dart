import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'constants.dart';
import 'core/models/transaction_id.dart';
import 'external/models/connection_data.dart';
import 'preferences.dart';
import 'provider/models/full_contract_state.dart';
import 'provider/models/network_changed_event.dart';
import 'provider/models/transactions_list.dart';
import 'provider/provider_events.dart';
import 'transport/gql_transport.dart';
import 'transport/transport.dart';

class ConnectionController {
  static ConnectionController? _instance;
  late final Preferences _preferences;
  final _transportSubject = BehaviorSubject<Transport>();

  ConnectionController._();

  static Future<ConnectionController> getInstance() async {
    if (_instance == null) {
      final instance = ConnectionController._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Stream<Transport> get transportStream => _transportSubject.stream.distinct();

  Transport get transport => _transportSubject.value;

  Future<void> updateTransport(ConnectionData connectionData) async {
    final old = _transportSubject.valueOrNull;

    final transport = await GqlTransport.create(connectionData);

    _transportSubject.add(transport);

    _preferences.setCurrentConnection(connectionData.name);

    await (old as GqlTransport?)?.free();
  }

  Future<FullContractState?> getFullAccountState(String address) => transport.getFullAccountState(address);

  Future<TransactionsList> getTransactions({
    required String address,
    TransactionId? continuation,
    int? limit,
  }) =>
      transport.getTransactions(
        address: address,
        continuation: continuation,
        limit: limit,
      );

  Future<void> _initialize() async {
    _preferences = await Preferences.getInstance();

    final currentConnection = kNetworkPresets.firstWhere(
      (e) => e.name == _preferences.getCurrentConnection(),
      orElse: () => kNetworkPresets.first,
    );

    await updateTransport(currentConnection);

    transportStream
        .transform<String>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(data.connectionData.name),
      ),
    )
        .listen((event) {
      networkChangedSubject.add(NetworkChangedEvent(selectedConnection: event));
    });
  }
}
