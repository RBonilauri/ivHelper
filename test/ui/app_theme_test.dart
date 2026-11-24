import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/ui/app_theme.dart';
import 'package:ivhelper/ui/type_badge.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('le mode nuit n\'utilise pas le jaune vif en aplat', () {
    final dark = buildTheme(Brightness.dark);
    const flashy = Color(0xFFFFCB05);
    expect(dark.colorScheme.primary, isNot(flashy));
    expect(dark.appBarTheme.backgroundColor, isNot(flashy));
    expect(dark.colorScheme.primaryContainer.computeLuminance(), lessThan(0.1));
  });

  test('le mode jour garde la barre jaune', () {
    final light = buildTheme(Brightness.light);
    expect(light.appBarTheme.backgroundColor, const Color(0xFFFFCB05));
  });

  test('formatFactor écrit les multiplicateurs à la française', () {
    expect(formatFactor(1.6), '×1,6');
    expect(formatFactor(1.6 * 1.6), '×2,56');
    expect(formatFactor(0.625), '×0,63');
    expect(formatFactor(0.390625), '×0,39');
    expect(formatFactor(1), '×1');
  });
}
