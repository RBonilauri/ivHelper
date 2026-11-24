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

  /// Lit l'équipe enregistrée (JSON), ou `null`.
  Future<String?> readTeam();

  /// Enregistre l'équipe (JSON).
  Future<void> writeTeam(String value);

  /// Lit la dernière méta téléchargée (JSON), ou `null`.
  Future<String?> readMeta();

  /// Enregistre la dernière méta téléchargée (JSON).
  Future<void> writeMeta(String value);

  /// Lit la collection enregistrée (JSON), ou `null`.
  Future<String?> readCollection();

  /// Enregistre la collection (JSON).
  Future<void> writeCollection(String value);

  /// Relit le stockage (une autre fenêtre, la pastille, a pu l'écrire).
  Future<void> refresh();

  /// Lit les dernières recherches (JSON), ou `null`.
  Future<String?> readHistory();

  /// Enregistre les dernières recherches (JSON).
  Future<void> writeHistory(String value);
}

/// Stockage en mémoire, sans persistance.
class MemorySettingsStore implements SettingsStore {
  String? _mode;
  double? _scale;
  String? _team;
  String? _meta;
  String? _collection;
  String? _history;

  @override
  Future<String?> readThemeMode() async => _mode;

  @override
  Future<double?> readFontScale() async => _scale;

  @override
  Future<void> writeThemeMode(String value) async => _mode = value;

  @override
  Future<void> writeFontScale(double value) async => _scale = value;

  @override
  Future<String?> readTeam() async => _team;

  @override
  Future<void> writeTeam(String value) async => _team = value;

  @override
  Future<String?> readMeta() async => _meta;

  @override
  Future<void> writeMeta(String value) async => _meta = value;

  @override
  Future<String?> readCollection() async => _collection;

  @override
  Future<void> writeCollection(String value) async => _collection = value;

  @override
  Future<void> refresh() async {}

  @override
  Future<String?> readHistory() async => _history;

  @override
  Future<void> writeHistory(String value) async => _history = value;
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
