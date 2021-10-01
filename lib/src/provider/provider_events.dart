import 'package:rxdart/subjects.dart';

import 'models/contract_state_changed_event.dart';
import 'models/error.dart' as provider_error;
import 'models/network_changed_event.dart';
import 'models/permissions_changed_event.dart';
import 'models/transactions_found_event.dart';

final providerDisconnectedSubject = PublishSubject<provider_error.Error>();

final providerDisconnectedStream = providerDisconnectedSubject.stream;

final providerTransactionsFoundSubject = PublishSubject<TransactionsFoundEvent>();

final providerTransactionsFoundStream = providerTransactionsFoundSubject.stream;

final providerContractStateChangedSubject = PublishSubject<ContractStateChangedEvent>();

final providerContractStateChangedStream = providerContractStateChangedSubject.stream;

final providerNetworkChangedSubject = PublishSubject<NetworkChangedEvent>();

final providerNetworkChangedStream = providerNetworkChangedSubject.stream;

final providerPermissionsChangedSubject = PublishSubject<PermissionsChangedEvent>();

final providerPermissionsChangedStream = providerPermissionsChangedSubject.stream;

final providerLoggedOutSubject = PublishSubject<Object>();

final providerLoggedOutStream = providerLoggedOutSubject.stream;
