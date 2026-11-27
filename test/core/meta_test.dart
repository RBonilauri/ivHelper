import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/league.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/poke_type.dart';

import '../support/fake_meta.dart';

void main() {
  final data = MetaSnapshot.fromJson(fakeMetaJson(withAltaria: true));
  final great = data.leagues[MetaLeague.great]!;

  List<String> names(List<MetaEntry> entries) =>
      <String>[for (final e in entries) e.name];

  test('sans filtre, toute la ligue', () {
    expect(names(filterMeta(great)), <String>['Flambusard', 'Altaria']);
  });

  test('type du Pokémon : un des types choisis suffit', () {
    expect(names(filterMeta(great, types: {PokeType.dragon})), ['Altaria']);
    expect(names(filterMeta(great, types: {PokeType.fire})), ['Flambusard']);
    expect(
      names(filterMeta(great, types: {PokeType.fire, PokeType.dragon})),
      ['Flambusard', 'Altaria'],
    );
  });

  test("type d'attaque : immédiate ou chargée recommandée", () {
    expect(names(filterMeta(great, moveTypes: {PokeType.fairy})), ['Altaria']);
    expect(
      names(filterMeta(great, moveTypes: {PokeType.flying})),
      ['Flambusard'],
    );
    expect(filterMeta(great, moveTypes: {PokeType.water}), isEmpty);
  });

  test('nom, types et possession se combinent', () {
    expect(names(filterMeta(great, query: 'ALTA')), ['Altaria']);
    expect(
      filterMeta(great, query: 'flamb', types: {PokeType.dragon}),
      isEmpty,
    );
    expect(
      names(filterMeta(great, keep: (e) => e.name == 'Flambusard')),
      ['Flambusard'],
    );
  });

  test('la fiche méta d\'une espèce dans une ligue', () {
    expect(data.entryFor('Altaria', MetaLeague.great)?.rank, 2);
    expect(data.entryFor('Altaria', MetaLeague.ultra), isNull);
    // Pas de forme obscure classée : la forme normale.
    expect(
      data.entryFor('Flambusard', MetaLeague.great, shadow: true)?.name,
      'Flambusard',
    );
  });

  test('ligue méta depuis la clé de ligue', () {
    expect(MetaLeague.fromKey('ultra'), MetaLeague.ultra);
    expect(MetaLeague.fromKey('little'), isNull);
  });

  group('coupes', () {
    final withCups = MetaSnapshot.fromJson(
      fakeMetaJson(
        withAltaria: true,
        cups: <Object?>[
          fakeCupJson(
            eligible: <String>['Flambusard', 'Altaria (Obscur)'],
          ),
          fakeCupJson(
            key: 'cauldron-2500',
            title: 'Battle Frontier (Cauldron)',
            league: 'ultra',
            entries: <Map<String, Object?>>[
              fakeMetaEntry(name: 'Altaria', species: 'Altaria'),
            ],
            eligible: <String>['Altaria', 'Tortank'],
          ),
        ],
      ),
    );

    test('lues avec leur limite de PC, après les trois ligues', () {
      expect(
        <String>[for (final b in withCups.boards) b.key],
        <String>['great', 'ultra', 'master', 'spectral-1500', 'cauldron-2500'],
      );
      final cup = withCups.cups.first;
      expect(cup.label, 'Battle Frontier (Spectral)');
      expect(cup.league, League.great);
      expect(cup.capLabel, '1500');
      expect(cup.isCup, isTrue);
      expect(cup.entries.single.name, 'Flambusard');
      final great = withCups.boardOf(MetaLeague.great);
      expect(great.label, 'Super');
      expect(great.league, League.great);
      expect(great.isCup, isFalse);
      expect(great.entries, hasLength(2));
      expect(withCups.boardByKey('cauldron-2500')?.label,
          'Battle Frontier (Cauldron)');
      expect(withCups.boardByKey('inconnue'), isNull);
      // Méta d'avant les coupes : aucune coupe.
      expect(data.cups, isEmpty);
    });

    test('droit de participer : espèce et forme obscure', () {
      final cup = withCups.cups.first;
      expect(cup.allows('Flambusard'), isTrue);
      expect(cup.allows('Flambusard', shadow: true), isFalse);
      expect(cup.allows('Altaria'), isFalse);
      expect(cup.allows('Altaria', shadow: true), isTrue);
      // Une ligue accepte tout le monde.
      expect(withCups.boardOf(MetaLeague.great).allows('Tortank'), isTrue);
      expect(cup.entryFor('Flambusard')?.rank, 1);
      expect(cup.entryFor('Tortank'), isNull);
    });

    test('coupes en cours qui acceptent une espèce, avec son rang', () {
      final all = cupStandings(withCups, 'Altaria');
      expect(<String>[for (final s in all) s.cup.key], <String>['cauldron-2500']);
      expect(all.single.entry?.rank, 1);
      expect(cupStandingLabel(all.single), 'n° 1');
      final tortank = cupStandings(withCups, 'Tortank');
      expect(tortank.single.entry, isNull);
      expect(cupStandingLabel(tortank.single), 'hors top 1');
      // Limitées à une ligue (même limite de PC).
      expect(cupStandings(withCups, 'Altaria', league: League.great), isEmpty);
      expect(
        cupStandings(withCups, 'Altaria', league: League.great, shadow: true)
            .single
            .cup
            .key,
        'spectral-1500',
      );
    });
  });
}
