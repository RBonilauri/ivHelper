import 'dart:convert';

import 'package:ivhelper/state/game_data_controller.dart';

/// `species.json` minimal : [count] espèces, Flambusard en premier.
String speciesJson({int count = 3, int atk = 176}) => jsonEncode(<Object>[
      for (var i = 0; i < count; i++)
        <String, Object>{
          'dex': 663 + i,
          'name': i == 0 ? 'Flambusard' : 'Espèce $i',
          'atk': i == 0 ? atk : 100,
          'def': 155,
          'sta': 186,
          'types': <String>['fire', 'flying'],
          'fast': <String>['INCINERATE'],
          'charged': <String>['BRAVE_BIRD'],
          'elite': <String>[],
          'stage': 0,
        },
    ]);

/// `moves.json` minimal.
String movesJson({String fastName = 'Calcination'}) => jsonEncode(<String, Object>{
      'INCINERATE': <String, Object>{
        'fast': true,
        'name': fastName,
        'power': 20,
        'type': 'fire',
      },
      'BRAVE_BIRD': <String, Object>{
        'fast': false,
        'name': 'Rapace',
        'power': 130,
        'energy': 55,
        'type': 'flying',
      },
    });

/// Version `game_data_version.json`.
String versionJson(String updated) => jsonEncode(<String, String>{'updated': updated});

/// Source de données du jeu sans réseau : [bundledUpdated] incluse, et en
/// ligne [remoteUpdated] avec [remoteSpecies] (`null` = hors ligne).
class FakeGameDataSource implements GameDataSource {
  FakeGameDataSource({
    this.bundledUpdated = '2026-11-20',
    this.remoteUpdated,
    String? remoteSpecies,
    String? remoteMoves,
  })  : remoteSpecies = remoteSpecies ?? speciesJson(atk: 200),
        remoteMoves = remoteMoves ?? movesJson(fastName: 'Calcination+');

  final String bundledUpdated;
  final String? remoteUpdated;
  final String remoteSpecies;
  final String remoteMoves;

  /// Nombre de téléchargements des espèces.
  int speciesFetches = 0;

  @override
  Future<String> bundledVersion() async => versionJson(bundledUpdated);

  @override
  Future<String> bundledSpecies() async => speciesJson();

  @override
  Future<String> bundledMoves() async => movesJson();

  @override
  Future<String> fetchVersion() async {
    final v = remoteUpdated;
    if (v == null) throw Exception('hors ligne');
    return versionJson(v);
  }

  @override
  Future<String> fetchSpecies() async {
    speciesFetches++;
    return remoteSpecies;
  }

  @override
  Future<String> fetchMoves() async => remoteMoves;
}
