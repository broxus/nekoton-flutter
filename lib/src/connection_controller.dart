import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'core/models/transaction_id.dart';
import 'external/models/connection_data.dart';
import 'provider/models/full_contract_state.dart';
import 'provider/models/network_changed_event.dart';
import 'provider/models/transactions_list.dart';
import 'provider/provider_events.dart';
import 'transport/gql_transport.dart';
import 'transport/transport.dart';

class ConnectionController {
  static const networkPresets = <ConnectionData>[
    ConnectionData(
      name: 'Mainnet (GQL 1)',
      group: 'mainnet',
      type: 'graphql',
      endpoint: 'https://main.ton.dev/',
      timeout: 60000,
    ),
    ConnectionData(
      name: 'Mainnet (GQL 2)',
      group: 'mainnet',
      type: 'graphql',
      endpoint: 'https://main2.ton.dev/',
      timeout: 60000,
    ),
    ConnectionData(
      name: 'Mainnet (GQL 3)',
      group: 'mainnet',
      type: 'graphql',
      endpoint: 'https://main3.ton.dev/',
      timeout: 60000,
    ),
    ConnectionData(
      name: 'Testnet',
      group: 'testnet',
      type: 'graphql',
      endpoint: 'https://net.ton.dev/',
      timeout: 60000,
    ),
    ConnectionData(
      name: 'fld.ton.dev',
      group: 'fld',
      type: 'graphql',
      endpoint: 'https://gql.custler.net/',
      timeout: 60000,
    ),
  ];
  static ConnectionController? _instance;
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
    final transport = await GqlTransport.getInstance(connectionData);

    _transportSubject.add(transport);
  }

  Future<FullContractState?> getFullAccountState({
    required String address,
  }) =>
      transport.getFullAccountState(address: address);

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
    await updateTransport(networkPresets[1]);

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
