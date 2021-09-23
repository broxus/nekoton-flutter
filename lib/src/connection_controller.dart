import 'package:rxdart/rxdart.dart';

import 'external/models/connection_data.dart';
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

  // Future<FullContractState> getFullContractState(String address) async => transport.getContractState(address: address);

  // Future<GetTransactionsOutput> getTransactions({
  //   required String address,
  //   required TransactionId continuation,
  //   int? limit = 50,
  // }) async =>
  //     transport.getTransactions(
  //       address: address,
  //       from: continuation,
  //       count: limit,
  //     );

  Future<void> _initialize() async {
    await updateTransport(networkPresets.first);
  }
}
