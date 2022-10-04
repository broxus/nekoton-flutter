import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:nekoton_flutter/src/bindings.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/account_to_add.dart';
import 'package:nekoton_flutter/src/core/accounts_storage/models/assets_list.dart';
import 'package:nekoton_flutter/src/core/utils.dart';
import 'package:nekoton_flutter/src/external/storage.dart';
import 'package:nekoton_flutter/src/ffi_utils.dart';
import 'package:rxdart/rxdart.dart';

final _nativeFinalizer =
    NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_accounts_storage_free_ptr);

class AccountsStorage implements Finalizable {
  late final Pointer<Void> _ptr;
  final _entriesSubject = BehaviorSubject<List<AssetsList>>();

  AccountsStorage._();

  static Future<AccountsStorage> create(Storage storage) async {
    final instance = AccountsStorage._();
    await instance._initialize(storage);
    return instance;
  }

  Pointer<Void> get ptr => _ptr;

  Stream<List<AssetsList>> get entriesStream =>
      _entriesSubject.distinct((a, b) => listEquals(a, b));

  List<AssetsList> get entries => _entriesSubject.value;

  Future<List<AssetsList>> get _entries async {
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

  static bool verify(String data) {
    final result = executeSync(
      () => NekotonFlutter.instance().bindings.nt_accounts_storage_verify_data(
            data.toNativeUtf8().cast<Char>(),
          ),
    );

    final isValid = result != 0;

    return isValid;
  }

  Future<AssetsList> addAccount(AccountToAdd newAccount) async {
    final newAccountStr = jsonEncode(newAccount);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_account(
            port,
            ptr,
            newAccountStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<List<AssetsList>> addAccounts(List<AccountToAdd> newAccounts) async {
    final newAccountsStr = jsonEncode(newAccounts);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_accounts(
            port,
            ptr,
            newAccountsStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<AssetsList> renameAccount({
    required String account,
    required String name,
  }) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_rename_account(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
            name.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<AssetsList> addTokenWallet({
    required String account,
    required String networkGroup,
    required String rootTokenContract,
  }) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_token_wallet(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
            networkGroup.toNativeUtf8().cast<Char>(),
            rootTokenContract.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<AssetsList> removeTokenWallet({
    required String account,
    required String networkGroup,
    required String rootTokenContract,
  }) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_token_wallet(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
            networkGroup.toNativeUtf8().cast<Char>(),
            rootTokenContract.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<AssetsList?> removeAccount(String account) async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_account(
            port,
            ptr,
            account.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as Map<String, dynamic>?;
    final entry = json != null ? AssetsList.fromJson(json) : null;

    return entry;
  }

  Future<List<AssetsList>> removeAccounts(List<String> accounts) async {
    final accountsStr = jsonEncode(accounts);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_accounts(
            port,
            ptr,
            accountsStr.toNativeUtf8().cast<Char>(),
          ),
    );

    await _updateData();

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<void> clear() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_clear(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> reload() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_reload(
            port,
            ptr,
          ),
    );

    await _updateData();
  }

  Future<void> dispose() => _entriesSubject.close();

  Future<void> _updateData() async => _entriesSubject.tryAdd(await _entries);

  Future<void> _initialize(Storage storage) async {
    final storagePtr = storage.ptr;

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_create(
            port,
            storagePtr,
          ),
    );

    _ptr = toPtrFromAddress(result as String);

    _nativeFinalizer.attach(this, _ptr);

    await _updateData();
  }
}
