import 'dart:convert';

import 'moves.dart';
import 'species_repository.dart';

/// Données du jeu (espèces et attaques), datées du jour où PvPoke les a
/// changées. La plus récente entre celles de l'appli, du cache et du dépôt
/// est utilisée.
class GameData {
  /// Crée les données.
  GameData({required this.updated, required this.species, required this.moves});

  /// Lit `species.json` et `moves.json` ; lève [FormatException] s'ils sont
  /// illisibles ou vides.
  factory GameData.parse({
    required String updated,
    required String speciesJson,
    required String movesJson,
  }) {
    final SpeciesRepository species;
    final MoveBook moves;
    try {
      species = SpeciesRepository.fromJson(speciesJson);
      moves = MoveBook.fromJson(movesJson);
    } on Object catch (e) {
      throw FormatException('Données du jeu illisibles : $e');
    }
    if (species.all.isEmpty || moves.all.isEmpty) {
      throw const FormatException('Données du jeu vides');
    }
    return GameData(updated: updated, species: species, moves: moves);
  }

  /// Date du dernier changement, `AAAA-MM-JJ`.
  final String updated;

  /// Espèces.
  final SpeciesRepository species;

  /// Attaques.
  final MoveBook moves;

  /// Vrai si ces données sont plus récentes que la date [other].
  bool isNewerThan(String other) => updated.compareTo(other) > 0;
}

final RegExp _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Date `AAAA-MM-JJ` de `game_data_version.json` ; [FormatException] sinon.
String readDataVersion(String json) {
  final decoded = jsonDecode(json);
  final updated = decoded is Map<String, dynamic> ? decoded['updated'] : null;
  if (updated is! String || !_date.hasMatch(updated)) {
    throw const FormatException('Version des données illisible');
  }
  return updated;
}

/// Cache des données téléchargées : un seul texte JSON.
String encodeGameDataCache({
  required String updated,
  required String speciesJson,
  required String movesJson,
}) =>
    jsonEncode(<String, String>{
      'updated': updated,
      'species': speciesJson,
      'moves': movesJson,
    });

/// Relit [encodeGameDataCache] ; [FormatException] si le cache est abîmé.
({String updated, String species, String moves}) decodeGameDataCache(
  String raw,
) {
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic> &&
      decoded['updated'] is String &&
      decoded['species'] is String &&
      decoded['moves'] is String &&
      _date.hasMatch(decoded['updated'] as String)) {
    return (
      updated: decoded['updated'] as String,
      species: decoded['species'] as String,
      moves: decoded['moves'] as String,
    );
  }
  throw const FormatException('Cache des données abîmé');
}

/// `AAAA-MM-JJ` → `JJ/MM/AAAA`.
String isoDateFr(String iso) =>
    _date.hasMatch(iso) ? '${iso.substring(8)}/${iso.substring(5, 7)}/${iso.substring(0, 4)}' : iso;
