import 'package:flutter/foundation.dart';

import '../core/game_data.dart';
import '../settings/settings_controller.dart';

/// D'où viennent les données du jeu : copie incluse dans l'appli et version
/// publiée chaque jour sur le dépôt.
abstract interface class GameDataSource {
  /// `assets/game_data_version.json` inclus.
  Future<String> bundledVersion();

  /// `assets/species.json` inclus.
  Future<String> bundledSpecies();

  /// `assets/moves.json` inclus.
  Future<String> bundledMoves();

  /// Version publiée sur le dépôt.
  Future<String> fetchVersion();

  /// Espèces publiées sur le dépôt.
  Future<String> fetchSpecies();

  /// Attaques publiées sur le dépôt.
  Future<String> fetchMoves();
}

/// Données du jeu utilisées par l'appli : la plus récente entre la copie
/// incluse et le cache, et une version plus récente téléchargée qui attend
/// d'être appliquée (au retour dans l'appli, pas sous les yeux).
class GameDataController extends ChangeNotifier {
  /// Crée le contrôleur.
  GameDataController({required this.source, required this.store});

  /// Source des données.
  final GameDataSource source;

  /// Cache de la dernière version téléchargée.
  final SettingsStore store;

  GameData? _current;
  GameData? _pending;

  /// Données en service ; [load] doit avoir été appelé.
  GameData get current => _current!;

  /// Version plus récente téléchargée, pas encore appliquée.
  GameData? get pending => _pending;

  /// Charge la plus récente entre la copie incluse et le cache.
  Future<void> load() async {
    var best = GameData.parse(
      updated: readDataVersion(await source.bundledVersion()),
      speciesJson: await source.bundledSpecies(),
      movesJson: await source.bundledMoves(),
    );
    final raw = await store.readGameData();
    if (raw != null) {
      try {
        final cached = decodeGameDataCache(raw);
        final data = GameData.parse(
          updated: cached.updated,
          speciesJson: cached.species,
          movesJson: cached.moves,
        );
        if (data.isNewerThan(best.updated)) best = data;
      } on FormatException {
        // Cache abîmé : la copie incluse suffit.
      }
    }
    _current = best;
  }

  /// Télécharge les données si le dépôt a plus récent ; vrai si une nouvelle
  /// version attend d'être appliquée. Hors ligne ou données abîmées ou
  /// incomplètes : rien ne change.
  Future<bool> refresh() async {
    final current = _current;
    if (current == null) return false;
    try {
      final updated = readDataVersion(await source.fetchVersion());
      final known = _pending?.updated ?? current.updated;
      if (updated.compareTo(known) <= 0) return false;
      final speciesJson = await source.fetchSpecies();
      final movesJson = await source.fetchMoves();
      final data = GameData.parse(
        updated: updated,
        speciesJson: speciesJson,
        movesJson: movesJson,
      );
      // Moins de 90 % des espèces actuelles : téléchargement incomplet.
      if (data.species.all.length * 10 < current.species.all.length * 9) {
        return false;
      }
      await store.writeGameData(
        encodeGameDataCache(
          updated: updated,
          speciesJson: speciesJson,
          movesJson: movesJson,
        ),
      );
      _pending = data;
      return true;
    } on Object {
      return false;
    }
  }

  /// Met en service la version téléchargée ; vrai s'il y en avait une.
  bool applyPending() {
    final next = _pending;
    if (next == null) return false;
    _current = next;
    _pending = null;
    notifyListeners();
    return true;
  }
}
