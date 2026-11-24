import 'package:shared_preferences/shared_preferences.dart';

import 'settings_controller.dart';

/// Réglages enregistrés dans les préférences de l'appareil.
class PrefsSettingsStore implements SettingsStore {
  /// Crée un stockage adossé à [prefs].
  const PrefsSettingsStore(this.prefs);

  /// Préférences de l'appareil.
  final SharedPreferences prefs;

  static const String _modeKey = 'themeMode';
  static const String _scaleKey = 'fontScale';
  static const String _teamKey = 'team';

  @override
  Future<String?> readThemeMode() async => prefs.getString(_modeKey);

  @override
  Future<double?> readFontScale() async => prefs.getDouble(_scaleKey);

  @override
  Future<void> writeThemeMode(String value) async {
    await prefs.setString(_modeKey, value);
  }

  @override
  Future<void> writeFontScale(double value) async {
    await prefs.setDouble(_scaleKey, value);
  }

  @override
  Future<String?> readTeam() async => prefs.getString(_teamKey);

  @override
  Future<void> writeTeam(String value) async {
    await prefs.setString(_teamKey, value);
  }
}
