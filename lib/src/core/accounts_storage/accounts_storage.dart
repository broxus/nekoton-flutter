import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../bindings.dart';
import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../models/pointer_wrapper.dart';
import 'models/account_to_add.dart';
import 'models/assets_list.dart';

final _nativeFinalizer = NativeFinalizer(NekotonFlutter.instance().bindings.addresses.nt_accounts_storage_free_ptr);

void _attach(PointerWrapper pointerWrapper) => _nativeFinalizer.attach(pointerWrapper, pointerWrapper.ptr);

class AccountsStorage {
  late final PointerWrapper pointerWrapper;

  AccountsStorage._();

  static Future<AccountsStorage> create(Storage storage) async {
    final instance = AccountsStorage._();
    await instance._initialize(storage);
    return instance;
  }

  Future<List<AssetsList>> get entries async {
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_entries(
            port,
            pointerWrapper.ptr,
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<AssetsList> addAccount(AccountToAdd newAccount) async {
    final newAccountStr = jsonEncode(newAccount);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_account(
            port,
            pointerWrapper.ptr,
            newAccountStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as Map<String, dynamic>;
    final entry = AssetsList.fromJson(json);

    return entry;
  }

  Future<List<AssetsList>> addAccounts(List<AccountToAdd> newAccounts) async {
    final newAccountsStr = jsonEncode(newAccounts);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_accounts(
            port,
            pointerWrapper.ptr,
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
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_rename_account(
            port,
            pointerWrapper.ptr,
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
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_add_token_wallet(
            port,
            pointerWrapper.ptr,
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
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_token_wallet(
            port,
            pointerWrapper.ptr,
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
    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_account(
            port,
            pointerWrapper.ptr,
            account.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result != null ? result as Map<String, dynamic> : null;
    final entry = json != null ? AssetsList.fromJson(json) : null;

    return entry;
  }

  Future<List<AssetsList>> removeAccounts(List<String> accounts) async {
    final accountsStr = jsonEncode(accounts);

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_remove_accounts(
            port,
            pointerWrapper.ptr,
            accountsStr.toNativeUtf8().cast<Char>(),
          ),
    );

    final json = result as List<dynamic>;
    final list = json.cast<Map<String, dynamic>>();
    final entries = list.map((e) => AssetsList.fromJson(e)).toList();

    return entries;
  }

  Future<void> clear() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_clear(
            port,
            pointerWrapper.ptr,
          ),
    );
  }

  Future<void> reload() async {
    await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_reload(
            port,
            pointerWrapper.ptr,
          ),
    );
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

  Future<void> _initialize(Storage storage) async {
    final storagePtr = storage.pointerWrapper.ptr;

    final result = await executeAsync(
      (port) => NekotonFlutter.instance().bindings.nt_accounts_storage_create(
            port,
            storagePtr,
          ),
    );

    pointerWrapper = PointerWrapper(Pointer.fromAddress(result as int).cast<Void>());

    _attach(pointerWrapper);
  }
}
