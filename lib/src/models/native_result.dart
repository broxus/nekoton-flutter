import 'dart:ffi';

import '../ffi_utils.dart';
import 'native_exception.dart';
import 'native_status.dart';

class NativeResult extends Struct {
  @Uint32()
  external int statusCode;

  @Uint64()
  external int payload;
}

extension Handle on NativeResult {
  int handle() {
    final status = NativeStatus.values[statusCode];

    switch (status) {
      case NativeStatus.success:
        return payload;
      case NativeStatus.mutexError:
        throw MutexException(cStringToDart(payload));
      case NativeStatus.conversionError:
        throw ConversionException(cStringToDart(payload));
      case NativeStatus.accountsStorageError:
        throw AccountsStorageException(cStringToDart(payload));
      case NativeStatus.keyStoreError:
        throw KeyStoreException(cStringToDart(payload));
      case NativeStatus.tokenWalletError:
        throw TokenWalletException(cStringToDart(payload));
      case NativeStatus.tonWalletError:
        throw TonWalletException(cStringToDart(payload));
      case NativeStatus.cryptoError:
        throw CryptoException(cStringToDart(payload));
      case NativeStatus.dePoolError:
        throw DePoolException(cStringToDart(payload));
      case NativeStatus.abiError:
        throw AbiException(cStringToDart(payload));
      case NativeStatus.transportError:
        throw TransportException(cStringToDart(payload));
    }
  }
}
