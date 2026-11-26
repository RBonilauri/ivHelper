import 'moves.dart';
import 'species_repository.dart';

/// Squelette.
class GameData {
  /// Squelette.
  GameData({required this.updated, required this.species, required this.moves});

  /// Squelette.
  factory GameData.parse({
    required String updated,
    required String speciesJson,
    required String movesJson,
  }) =>
      GameData(
        updated: updated,
        species: SpeciesRepository(const <Species>[]),
        moves: MoveBook(const <Move>[]),
      );

  /// Squelette.
  final String updated;

  /// Squelette.
  final SpeciesRepository species;

  /// Squelette.
  final MoveBook moves;

  /// Squelette.
  bool isNewerThan(String other) => false;
}

/// Squelette.
String readDataVersion(String json) => '';

/// Squelette.
String encodeGameDataCache({
  required String updated,
  required String speciesJson,
  required String movesJson,
}) =>
    '';

/// Squelette.
({String updated, String species, String moves}) decodeGameDataCache(
  String raw,
) =>
    (updated: '', species: '', moves: '');
