import '../../bindings.dart';
import '../../ffi_utils.dart';

String accountsStorageKey() {
  final result = NekotonFlutter.bindings.nt_accounts_storage_key();

  final key = cStringToDart(result.address);

  return key;
}
