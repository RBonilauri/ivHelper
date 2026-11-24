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
  static const String _metaKey = 'meta';
  static const String _collectionKey = 'collection';
  static const String _historyKey = 'history';

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

  @override
  Future<String?> readMeta() async => prefs.getString(_metaKey);

  @override
  Future<void> writeMeta(String value) async {
    await prefs.setString(_metaKey, value);
  }

  @override
  Future<String?> readCollection() async => prefs.getString(_collectionKey);

  @override
  Future<void> writeCollection(String value) async {
    await prefs.setString(_collectionKey, value);
  }

  @override
  Future<String?> readHistory() async => prefs.getString(_historyKey);

  @override
  Future<void> writeHistory(String value) async {
    await prefs.setString(_historyKey, value);
  }

  @override
  Future<void> refresh() => prefs.reload();
}
