import 'dart:math';

import '../nekoton_flutter.dart';
import 'constants.dart';
import 'core/keystore/models/key_store_entry.dart';

extension TokensConvert on String {
  String toTokens([int decimals = kTonDecimals]) {
    final radix = BigInt.from(pow(10, decimals));

    final number = BigInt.parse(this);

    final lead = number ~/ radix;
    final leadStr = lead.toString();

    final trail = number % radix;
    var trailStr = trail.toString();

    if (trailStr.length > decimals) {
      trailStr = trailStr.substring(0, decimals);
    }

    trailStr = trailStr.padLeft(decimals, '0');

    return '$leadStr.$trailStr';
  }

  String fromTokens([int decimals = kTonDecimals]) {
    final radix = BigInt.from(pow(10, decimals));

    final dotIndex = indexOf('.');

    if (dotIndex != -1) {
      final integerStr = substring(0, dotIndex);
      final integer = BigInt.parse(integerStr);

      var decimalStr = substring(dotIndex + 1);
      decimalStr =
          decimalStr.length > decimals ? decimalStr.substring(0, decimals) : decimalStr.padRight(decimals, '0');

      if (integer > BigInt.zero) {
        return '$integer$decimalStr';
      } else {
        final result = BigInt.parse(decimalStr);
        return result.toString();
      }
    } else {
      final result = BigInt.parse(this) * radix;
      return result.toString();
    }
  }
}

extension VersionConvert on String {
  int toInt() {
    final parts = split('.');

    if (parts.length != 3) {
      throw Exception('Received invalid version string');
    }

    for (final part in parts) {
      if (int.parse(part) > 999) {
        throw Exception('Version string invalid, $part is too large');
      }
    }

    int multiplier = 1000000;
    int numericVersion = 0;

    for (var i = 0; i < 3; i++) {
      numericVersion += int.parse(parts[i]) * multiplier;
      multiplier = multiplier ~/ 1000;
    }

    return numericVersion;
  }
}

int sortKeys(KeyStoreEntry a, KeyStoreEntry b) => b.publicKey.compareTo(a.publicKey);

int sortAccounts(AssetsList a, AssetsList b) => b.address.compareTo(a.address);

int sortTonWallets(TonWallet a, TonWallet b) => b.walletType.toInt().compareTo(a.walletType.toInt());

int sortTokenWallets(TokenWallet a, TokenWallet b) => b.symbol.name.compareTo(a.symbol.name);
