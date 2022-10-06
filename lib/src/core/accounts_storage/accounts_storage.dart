import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../../bindings.dart';
import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../models/pointed.dart';
import 'models/account_to_add.dart';
import 'models/assets_list.dart';

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
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_entries(
            port,
            ptr,
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<AssetsList> addAccount(AccountToAdd newAccount) async {
    final ptr = await clonePtr();
    final newAccountStr = jsonEncode(newAccount);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_account(
            port,
            ptr,
            newAccountStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<List<AssetsList>> addAccounts(List<AccountToAdd> newAccounts) async {
    final ptr = await clonePtr();
    final newAccountsStr = jsonEncode(newAccounts);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_accounts(
            port,
            ptr,
            newAccountsStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<AssetsList> renameAccount({
    required String account,
    required String name,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_rename_account(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
            name.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<AssetsList> addTokenWallet({
    required String account,
    required String networkGroup,
    required String rootTokenContract,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_token_wallet(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
            networkGroup.toNativeUtf8().cast<Char>(),
            rootTokenContract.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<AssetsList> removeTokenWallet({
    required String account,
    required String networkGroup,
    required String rootTokenContract,
  }) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_token_wallet(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
            networkGroup.toNativeUtf8().cast<Char>(),
            rootTokenContract.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<AssetsList?> removeAccount(String account) async {
    final ptr = await clonePtr();

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_account(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>?;
    final entry = json != null ? AssetsList.fromJson(json) : null;

    return entry;
  }

  Future<List<AssetsList>> removeAccounts(List<String> accounts) async {
    final ptr = await clonePtr();
    final accountsStr = jsonEncode(accounts);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_accounts(
            port,
            ptr,
            accountsStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<void> clear() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_clear(
            port,
            ptr,
          ),
    );
  }

  Future<void> reload() async {
    final ptr = await clonePtr();

    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_reload(
            port,
            ptr,
          ),
    );
  }

  @override
  Future<Pointer<Void>> clonePtr() => _lock.synchronized(() {
        if (_ptr == null) throw Exception('Accounts storage use after free');

        final ptr = NekotonFlutter.instance().bindings.nt_accounts_storage_clone_ptr(
              _ptr!,
            );

        return ptr;
      });

  @override
  Future<void> freePtr() => _lock.synchronized(() {
        if (_ptr == null) return;

        NekotonFlutter.instance().bindings.nt_accounts_storage_free_ptr(
              _ptr!,
            );

        _ptr = null;
      });

  Future<void> _initialize(Storage storage) => _lock.synchronized(() async {
        final storagePtr = await storage.clonePtr();

        final result = await executeAsync(
          (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_create(
                port,
                storagePtr,
              ),
        );

        _ptr = toPtrFromAddress(result as String);
      });
}
