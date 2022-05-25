import '../../bindings.dart';
import '../../ffi_utils.dart';

String keystoreStorageKey() {
  final result = NekotonFlutter.bindings.nt_keystore_storage_key();

  final key = cStringToDart(result.address);

  return key;
}
