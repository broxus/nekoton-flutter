import 'package:rxdart/subjects.dart';

import 'models/contract_state_changed_event.dart';
import 'models/error.dart' as provider_error;
import 'models/network_changed_event.dart';
import 'models/permissions_changed_event.dart';
import 'models/transactions_found_event.dart';

final disconnectedSubject = PublishSubject<provider_error.Error>();

final disconnectedStream = disconnectedSubject.stream;

final transactionsFoundSubject = PublishSubject<TransactionsFoundEvent>();

final transactionsFoundStream = transactionsFoundSubject.stream;

final contractStateChangedSubject = PublishSubject<ContractStateChangedEvent>();

final contractStateChangedStream = contractStateChangedSubject.stream;

final networkChangedSubject = PublishSubject<NetworkChangedEvent>();

final networkChangedStream = networkChangedSubject.stream;

final permissionsChangedSubject = PublishSubject<PermissionsChangedEvent>();

final permissionsChangedStream = permissionsChangedSubject.stream;

final loggedOutSubject = PublishSubject<Object>();

final loggedOutStream = loggedOutSubject.stream;
