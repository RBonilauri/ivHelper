import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/collection.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/collection_controller.dart';
import 'package:ivhelper/state/meta_controller.dart';
import 'package:ivhelper/state/team_controller.dart';
import 'package:ivhelper/ui/team_builder_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_meta.dart';

Species _species(int dex, String name, PokeType type, String fast) => Species(
      dex: dex,
      nameFr: name,
      base: const BaseStats(180, 160, 160),
      types: <PokeType>[type],
      fastMoves: <String>[fast],
    );

final SpeciesRepository _repository = SpeciesRepository(<Species>[
  _species(9, 'Tortank', PokeType.water, 'WATER_GUN'),
  _species(392, 'Simiabraz', PokeType.fire, 'EMBER'),
  _species(466, 'Élekable', PokeType.electric, 'THUNDER_SHOCK'),
]);

final MoveBook _moves = MoveBook(const <Move>[
  Move(id: 'WATER_GUN', nameFr: 'Pistolet à O', type: PokeType.water, isFast: true),
  Move(id: 'EMBER', nameFr: 'Flammèche', type: PokeType.fire, isFast: true),
  Move(
    id: 'THUNDER_SHOCK',
    nameFr: 'Éclair',
    type: PokeType.electric,
    isFast: true,
  ),
]);

Map<String, Object?> _opponent(
  int rank,
  String name,
  List<String> types,
  String move,
) =>
    <String, Object?>{
      'rank': rank,
      'name': name,
      'species': name,
      'shadow': false,
      'types': types,
      'score': 90,
      'fast': <String, String>{'id': 'X$rank', 'name': 'X', 'type': move},
      'charged': <Object?>[],
      'bestMatchups': <String>[],
      'worstMatchups': <String>[],
    };

final String _metaJson = jsonEncode(<String, Object?>{
  'updated': '2026-11-27',
  'source': 'PvPoke',
  'leagues': <String, Object?>{
    'great': <Object?>[
      _opponent(1, 'Feunard', <String>['fire'], 'fire'),
      _opponent(2, 'Ptéra', <String>['grass'], 'grass'),
      _opponent(3, 'Corvaillus', <String>['steel', 'flying'], 'flying'),
    ],
    'ultra': <Object?>[],
    'master': <Object?>[],
  },
});

void main() {
  testWidgets('« Ma meilleure équipe » propose et place trois Pokémon',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemorySettingsStore();
    final collection = CollectionController(
      repository: _repository,
      moves: _moves,
      store: store,
    );
    final team =
        TeamController(repository: _repository, moves: _moves, store: store);
    final meta = MetaController(
      source: FakeMetaSource(local: _metaJson),
      store: store,
    );
    await tester.runAsync(meta.ensureLoaded);
    const iv = Iv(0, 15, 15);
    final ids = <String, String>{};
    for (final s in <String>['Tortank', 'Simiabraz', 'Élekable']) {
      final species = _repository.findByName(s)!;
      ids[s] = collection
          .add(
            species,
            iv,
            50,
            SaveOptions(league: League.great, fastMove: species.fastMoves.first),
          )
          .id;
    }
    // Tortank déjà dans le troisième emplacement : il doit pouvoir passer
    // dans le premier.
    team.importFromCollection(2, ids['Tortank']!, _repository.findByName('Tortank')!);

    await tester.pumpWidget(
      MaterialApp(
        home: TeamBuilderScreen(team: team, collection: collection, meta: meta),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('best-team')));
    await tester.pumpAndSettle();
    expect(find.text('Couvre 100 % du top 3'), findsOneWidget);
    expect(find.text('3 adversaires contrés sur 3'), findsOneWidget);

    // En Hyper, rien n'est tagué.
    await tester.tap(find.byKey(const ValueKey<String>('best-league-ultra')));
    await tester.pumpAndSettle();
    expect(
      find.text('Il faut au moins trois espèces différentes tagguées en '
          'ligue Hyper dans ta collection.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('best-league-great')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('best-use-0')));
    await tester.pumpAndSettle();
    expect(
      <String?>[for (final s in team.slots) s.species?.nameFr],
      <String>['Tortank', 'Simiabraz', 'Élekable'],
    );
    expect(
      <String?>[for (final s in team.slots) s.collectionId],
      <String?>[ids['Tortank'], ids['Simiabraz'], ids['Élekable']],
    );
    expect(team.slots[1].fast?.id, 'EMBER');
  });
}
