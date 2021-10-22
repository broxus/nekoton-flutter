import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../nekoton.dart';
import 'models/assets_list.dart';
import 'models/native_accounts_storage.dart';
import 'models/wallet_type.dart';

class AccountsStorage {
  static AccountsStorage? _instance;
  late final Storage _storage;
  late final NativeAccountsStorage _nativeAccountsStorage;

  AccountsStorage._();

  static Future<AccountsStorage> getInstance() async {
    if (_instance == null) {
      final instance = AccountsStorage._();
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<List<AssetsList>> get accounts async {
    final result = await _nativeAccountsStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_accounts(
          port,
          ptr,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as List<dynamic>;
    final jsonList = json.cast<Map<String, dynamic>>();
    final list = jsonList.map((e) => AssetsList.fromJson(e)).toList();

    return list;
  }

  Future<AssetsList> addAccount({
    required String name,
    required String publicKey,
    required WalletType walletType,
    required int workchain,
  }) async {
    final walletTypeStr = jsonEncode(walletType);

    final result = await _nativeAccountsStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.add_account(
          port,
          ptr,
          name.toNativeUtf8().cast<Int8>(),
          publicKey.toNativeUtf8().cast<Int8>(),
          walletTypeStr.toNativeUtf8().cast<Int8>(),
          workchain,
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<AssetsList> renameAccount({
    required String address,
    required String name,
  }) async {
    final result = await _nativeAccountsStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.rename_account(
          port,
          ptr,
          address.toNativeUtf8().cast<Int8>(),
          name.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<AssetsList?> removeAccount(String address) async {
    final result = await _nativeAccountsStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.remove_account(
          port,
          ptr,
          address.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>?;
    final list = json != null ? AssetsList.fromJson(json) : null;

    return list;
  }

  Future<AssetsList> addTokenWallet({
    required String address,
    required String rootTokenContract,
    required String networkGroup,
  }) async {
    final result = await _nativeAccountsStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.add_token_wallet(
          port,
          ptr,
          address.toNativeUtf8().cast<Int8>(),
          networkGroup.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<AssetsList> removeTokenWallet({
    required String address,
    required String rootTokenContract,
    required String networkGroup,
  }) async {
    final result = await _nativeAccountsStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.remove_token_wallet(
          port,
          ptr,
          address.toNativeUtf8().cast<Int8>(),
          networkGroup.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ),
      ),
    );

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<void> clear() async => _nativeAccountsStorage.use(
        (ptr) async => proceedAsync(
          (port) => nativeLibraryInstance.bindings.clear_accounts_storage(
            port,
            ptr,
          ),
        ),
      );

  Future<void> free() async => _nativeAccountsStorage.free();

  Future<void> _initialize() async {
    _storage = await Storage.getInstance();

    final result = await _storage.nativeStorage.use(
      (ptr) async => proceedAsync(
        (port) => nativeLibraryInstance.bindings.get_accounts_storage(
          port,
          ptr,
        ),
      ),
    );
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeAccountsStorage = NativeAccountsStorage(ptr);
  }
}
