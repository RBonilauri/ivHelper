import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('valeurs par défaut : mode système, police normale', () {
    final c = SettingsController(MemorySettingsStore());
    expect(c.themeMode, ThemeMode.system);
    expect(c.fontScale, 1);
  });

  test('les réglages sont enregistrés puis rechargés', () async {
    final store = MemorySettingsStore();
    final a = SettingsController(store);
    await a.setThemeMode(ThemeMode.dark);
    await a.setFontScale(1.2);
    final b = SettingsController(store);
    await b.load();
    expect(b.themeMode, ThemeMode.dark);
    expect(b.fontScale, 1.2);
  });

  test('l\'échelle de police est bornée', () async {
    final c = SettingsController(MemorySettingsStore());
    await c.setFontScale(5);
    expect(c.fontScale, SettingsController.maxFontScale);
    await c.setFontScale(0.1);
    expect(c.fontScale, SettingsController.minFontScale);
  });
}
