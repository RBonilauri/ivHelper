import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Stockage des réglages : mémoire en test, préférences sur l'appareil.
abstract interface class SettingsStore {
  /// Lit le mode de thème enregistré ('system', 'light' ou 'dark').
  Future<String?> readThemeMode();

  /// Lit l'échelle de police enregistrée.
  Future<double?> readFontScale();

  /// Enregistre le mode de thème.
  Future<void> writeThemeMode(String value);

  /// Enregistre l'échelle de police.
  Future<void> writeFontScale(double value);
}

/// Stockage en mémoire, sans persistance.
class MemorySettingsStore implements SettingsStore {
  String? _mode;
  double? _scale;

  @override
  Future<String?> readThemeMode() async => _mode;

  @override
  Future<double?> readFontScale() async => _scale;

  @override
  Future<void> writeThemeMode(String value) async => _mode = value;

  @override
  Future<void> writeFontScale(double value) async => _scale = value;
}

/// Réglages de l'application : mode d'affichage et taille de police.
class SettingsController extends ChangeNotifier {
  /// Crée un contrôleur adossé à [store].
  SettingsController(this.store);

  /// Plus petite échelle de police proposée.
  static const double minFontScale = 0.85;

  /// Plus grande échelle de police proposée.
  static const double maxFontScale = 1.4;

  /// Stockage des réglages.
  final SettingsStore store;

  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1;

  /// Mode clair, sombre ou suivant le système.
  ThemeMode get themeMode => _themeMode;

  /// Échelle appliquée à toutes les polices (1 = normale).
  double get fontScale => _fontScale;

  /// Charge les réglages enregistrés.
  Future<void> load() async {
    final mode = await store.readThemeMode();
    final scale = await store.readFontScale();
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => ThemeMode.system,
    );
    _fontScale = (scale ?? 1).clamp(minFontScale, maxFontScale);
    notifyListeners();
  }

  /// Change le mode d'affichage.
  Future<void> setThemeMode(ThemeMode value) async {
    if (value == _themeMode) return;
    _themeMode = value;
    notifyListeners();
    await store.writeThemeMode(value.name);
  }

  /// Change l'échelle de police, bornée entre [minFontScale] et [maxFontScale].
  Future<void> setFontScale(double value) async {
    final next = value.clamp(minFontScale, maxFontScale);
    if (next == _fontScale) return;
    _fontScale = next;
    notifyListeners();
    await store.writeFontScale(next);
  }
}
