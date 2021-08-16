import 'dart:math';

import 'constants.dart';

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
