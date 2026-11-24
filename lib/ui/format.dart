/// Stat tronquée à une décimale, avec une virgule (comme le calculateur de
/// référence).
String formatStat(double value) {
  final truncated = (value * 10).floor() / 10;
  return truncated.toStringAsFixed(1).replaceAll('.', ',');
}

/// Pourcentage à deux décimales avec une virgule ; « 100 % » s'il arrondit à
/// 100.
String formatPercent(double value) {
  final text = value.toStringAsFixed(2);
  if (text == '100.00') return '100 %';
  return '${text.replaceAll('.', ',')} %';
}

/// Entier avec une espace insécable entre les milliers.
String formatGrouped(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Niveau sans décimale s'il est entier, sinon avec une virgule.
String formatLevel(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
