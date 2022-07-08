import 'package:bloc/bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:nekoton_flutter_example/data/nekoton_repository.dart';

class AccountsCubit extends Cubit<List<AssetsList>> {
  final NekotonRepository _nekotonRepository;

  AccountsCubit(this._nekotonRepository) : super([]) {
    addAccounts();
  }

  Future<void> addAccounts() async {
    final accountsStorage = await _nekotonRepository.accountsStorage;

    final entries = accountsStorage.entries;

    emit(entries);

    if (entries.isNotEmpty) return;

    await accountsStorage.addAccount(
      const AccountToAdd(
        name: 'legacy_key_account',
        publicKey: '5b8184e364391a83fe5cb4f8942f78c07a105a42d16ab2cf9fca0c93dab37110',
        contract: WalletType.walletV3(),
        workchain: 0,
      ),
    );

    await accountsStorage.addAccount(
      const AccountToAdd(
        name: 'hd_key_account',
        publicKey: 'fa11e1c92655eeb9755c2ec50325ce6e104804f08bcdd75b1603408276ae2360',
        contract: WalletType.multisig(MultisigType.safeMultisigWallet),
        workchain: 0,
      ),
    );

    await accountsStorage.addAccount(
      const AccountToAdd(
        name: 'ledger_key_account',
        publicKey: '5b8184e364391a83fe5cb4f8942f78c07a105a42d16ab2cf9fca0c93dab37110',
        contract: WalletType.multisig(MultisigType.setcodeMultisigWallet),
        workchain: 0,
      ),
    );

    emit(accountsStorage.entries);
  }
}
