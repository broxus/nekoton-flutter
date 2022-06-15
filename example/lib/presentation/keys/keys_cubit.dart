import 'package:bloc/bloc.dart';
import 'package:nekoton_flutter/nekoton_flutter.dart';

import '../../data/nekoton_repository.dart';

class KeysCubit extends Cubit<List<KeyStoreEntry>> {
  final NekotonRepository _nekotonRepository;

  KeysCubit(this._nekotonRepository) : super([]) {
    addKeys();
  }

  Future<void> addKeys() async {
    final keystore = await _nekotonRepository.keystore;

    final entries = await keystore.entries;

    emit(entries);

    if (entries.isNotEmpty) return;

    const phraseLabs = 'shed train diesel surprise finish already comfort asset swarm ivory defy';
    const phraseLegacy =
        'country glue knife buzz bus armor cement offer guide corn buddy update bird alcohol either neglect demand uncover table lock ketchup dinner ramp cream';

    await keystore.addKey(
      const EncryptedKeyCreateInput(
        name: 'legacy_key',
        phrase: phraseLegacy,
        mnemonicType: MnemonicType.labs(0),
        password: Password.explicit(
          PasswordExplicit(
            password: 'password',
            cacheBehavior: PasswordCacheBehavior.nop(),
          ),
        ),
      ),
    );

    await keystore.addKey(
      const DerivedKeyCreateInput.import(
        DerivedKeyCreateInputImport(
          keyName: 'hd_key',
          phrase: phraseLabs,
          password: Password.explicit(
            PasswordExplicit(
              password: 'password',
              cacheBehavior: PasswordCacheBehavior.nop(),
            ),
          ),
        ),
      ),
    );

    await keystore.addKey(
      const LedgerKeyCreateInput(
        name: 'ledger_key',
        accountId: 0,
      ),
    );

    emit(await keystore.entries);
  }
}
