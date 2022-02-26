import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import 'models/assets_list.dart';
import 'models/wallet_type.dart';

class AccountsStorage implements Pointed {
  final _lock = Lock();
  Pointer<Void>? _ptr;

  AccountsStorage._();

  static Future<AccountsStorage> create(Storage storage) async {
    final instance = AccountsStorage._();
    await instance._initialize(storage);
    return instance;
  }

  Future<List<AssetsList>> get accounts async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().get_accounts(
        port,
        ptr,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final accounts = list.map((e) => AssetsList.fromJson(e)).toList();

    return accounts;
  }

  Future<AssetsList> addAccount({
    required String name,
    required String publicKey,
    required WalletType walletType,
    required int workchain,
  }) async {
    final ptr = await clonePtr();
    final walletTypeStr = jsonEncode(walletType);

    final result = await executeAsync(
      (port) => bindings().add_account(
        port,
        ptr,
        name.toNativeUtf8().cast<Int8>(),
        publicKey.toNativeUtf8().cast<Int8>(),
        walletTypeStr.toNativeUtf8().cast<Int8>(),
        workchain,
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final account = AssetsList.fromJson(json);

    return account;
  }

  Future<AssetsList> renameAccount({
    required String address,
    required String name,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().rename_account(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
        name.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final account = AssetsList.fromJson(json);

    return account;
  }

  Future<AssetsList?> removeAccount(String address) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().remove_account(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;
    final account = json != null ? AssetsList.fromJson(json) : null;

    return account;
  }

  Future<AssetsList> addTokenWallet({
    required String address,
    required String rootTokenContract,
    required String networkGroup,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().add_token_wallet(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
        networkGroup.toNativeUtf8().cast<Int8>(),
        rootTokenContract.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final account = AssetsList.fromJson(json);

    return account;
  }

  Future<AssetsList> removeTokenWallet({
    required String address,
    required String rootTokenContract,
    required String networkGroup,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => bindings().remove_token_wallet(
        port,
        ptr,
        address.toNativeUtf8().cast<Int8>(),
        networkGroup.toNativeUtf8().cast<Int8>(),
        rootTokenContract.toNativeUtf8().cast<Int8>(),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final account = AssetsList.fromJson(json);

    return account;
  }

  Future<void> clear() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => bindings().clear_accounts_storage(
        port,
        ptr,
      ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Accounts storage use after free');

        final ptr = bindings().clone_accounts_storage_ptr(
          _ptr!,
        );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Accounts storage use after free');

        bindings().free_accounts_storage_ptr(
          _ptr!,
        );

        _ptr = null;
      });

  Future<void> _initialize(Storage storage) => _lock.synchronized(() async {
        final storagePtr = await storage.clonePtr();

        final result = await executeAsync(
          (port) => bindings().create_accounts_storage(
            port,
            storagePtr,
          ),
        );

        _ptr = Pointer.fromAddress(result).cast<Void>();
      });
}
