import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';

import '../../external/storage.dart';
import '../../ffi_utils.dart';
import '../../native_library.dart';
import 'models/assets_list.dart';
import 'models/native_accounts_storage.dart';
import 'models/wallet_type.dart';

class AccountsStorage {
  static AccountsStorage? _instance;
  final _nativeLibrary = NativeLibrary.instance();
  final Logger? _logger;
  late final Storage _storage;
  late final NativeAccountsStorage _nativeAccountsStorage;

  AccountsStorage._(this._logger);

  static Future<AccountsStorage> getInstance({
    Logger? logger,
  }) async {
    if (_instance == null) {
      final instance = AccountsStorage._(logger);
      await instance._initialize();
      _instance = instance;
    }

    return _instance!;
  }

  Future<List<AssetsList>> get accounts async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_accounts(
          port,
          _nativeAccountsStorage.ptr!,
        ));

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
    final contractTypeStr = jsonEncode(walletType.toJson());

    final result = await proceedAsync((port) => _nativeLibrary.bindings.add_account(
          port,
          _nativeAccountsStorage.ptr!,
          name.toNativeUtf8().cast<Int8>(),
          publicKey.toNativeUtf8().cast<Int8>(),
          contractTypeStr.toNativeUtf8().cast<Int8>(),
          workchain,
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<AssetsList> renameAccount({
    required String address,
    required String name,
  }) async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.rename_account(
          port,
          _nativeAccountsStorage.ptr!,
          address.toNativeUtf8().cast<Int8>(),
          name.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<AssetsList?> removeAccount(String address) async {
    final result = await proceedAsync((port) => _nativeLibrary.bindings.remove_account(
          port,
          _nativeAccountsStorage.ptr!,
          address.toNativeUtf8().cast<Int8>(),
        ));

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
    final result = await proceedAsync((port) => _nativeLibrary.bindings.add_token_wallet(
          port,
          _nativeAccountsStorage.ptr!,
          address.toNativeUtf8().cast<Int8>(),
          networkGroup.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ));

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
    final result = await proceedAsync((port) => _nativeLibrary.bindings.remove_token_wallet(
          port,
          _nativeAccountsStorage.ptr!,
          address.toNativeUtf8().cast<Int8>(),
          networkGroup.toNativeUtf8().cast<Int8>(),
          rootTokenContract.toNativeUtf8().cast<Int8>(),
        ));

    final string = cStringToDart(result);
    final json = jsonDecode(string) as Map<String, dynamic>;
    final list = AssetsList.fromJson(json);

    return list;
  }

  Future<void> clear() async => proceedAsync((port) => _nativeLibrary.bindings.clear_accounts_storage(
        port,
        _nativeAccountsStorage.ptr!,
      ));

  Future<void> _initialize() async {
    _storage = await Storage.getInstance(logger: _logger);

    final result = await proceedAsync((port) => _nativeLibrary.bindings.get_accounts_storage(
          port,
          _storage.nativeStorage.ptr!,
        ));
    final ptr = Pointer.fromAddress(result).cast<Void>();

    _nativeAccountsStorage = NativeAccountsStorage(ptr);
  }

  @override
  String toString() => 'AccountsStorage(${_nativeAccountsStorage.ptr?.address})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is AccountsStorage && other._nativeAccountsStorage.ptr?.address == _nativeAccountsStorage.ptr?.address;

  @override
  int get hashCode => _nativeAccountsStorage.ptr?.address ?? 0;
}