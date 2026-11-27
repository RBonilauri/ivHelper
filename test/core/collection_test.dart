import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/collection.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';

const _ember =
    Move(id: 'EMBER', nameFr: 'Flammèche', type: PokeType.fire, isFast: true);
const _bubble =
    Move(id: 'BUBBLE', nameFr: 'Écume', type: PokeType.water, isFast: true);
const _braveBird = Move(
  id: 'BRAVE_BIRD',
  nameFr: 'Rapace',
  type: PokeType.flying,
  isFast: false,
);

CollectionRow _row(
  String name,
  int dex,
  List<PokeType> types,
  League league,
  int rank, {
  List<Move> recorded = const <Move>[],
  List<Move> learnable = const <Move>[],
  bool favorite = false,
}) {
  return CollectionRow(
    entry: CollectionEntry(
      id: name,
      speciesName: name,
      iv: const Iv(15, 15, 15),
      maxLevel: 51,
      league: league,
      rank: rank,
      percent: 90,
      cp: 1500,
      level: 40,
      favorite: favorite,
    ),
    species: Species(
      dex: dex,
      nameFr: name,
      base: const BaseStats(100, 100, 100),
      types: types,
    ),
    recordedMoves: recorded,
    learnableMoves: learnable,
  );
}

final _rows = <CollectionRow>[
  _row(
    'Flambusard',
    663,
    <PokeType>[PokeType.fire, PokeType.flying],
    League.ultra,
    1,
    recorded: <Move>[_braveBird],
    learnable: <Move>[_ember, _braveBird],
  ),
  _row('Carapuce', 7, <PokeType>[PokeType.water], League.little, 8,
      learnable: <Move>[_bubble]),
  _row('Écayon', 550, <PokeType>[PokeType.water], League.great, 45,
      learnable: <Move>[_bubble]),
  _row('Salamèche', 4, <PokeType>[PokeType.fire], League.great, 600,
      learnable: <Move>[_ember]),
];

List<String> _names(Iterable<CollectionRow> rows) =>
    <String>[for (final r in rows) r.species.nameFr];

List<String> _apply(CollectionFilter f, [CollectionSort s = CollectionSort.dex]) =>
    _names(filterAndSort(_rows, f, s));

void main() {
  test('tri par rang, Pokédex, nom (accents ignorés) et type', () {
    const all = CollectionFilter();
    expect(_apply(all, CollectionSort.rank),
        <String>['Flambusard', 'Carapuce', 'Écayon', 'Salamèche']);
    expect(_apply(all, CollectionSort.dex),
        <String>['Salamèche', 'Carapuce', 'Écayon', 'Flambusard']);
    expect(_apply(all, CollectionSort.name),
        <String>['Carapuce', 'Écayon', 'Flambusard', 'Salamèche']);
    expect(_apply(all, CollectionSort.type),
        <String>['Salamèche', 'Flambusard', 'Carapuce', 'Écayon']);
  });

  test('filtre de ligue : celle du tag', () {
    expect(_apply(const CollectionFilter(league: League.great)),
        <String>['Salamèche', 'Écayon']);
    expect(_apply(const CollectionFilter(league: League.master)), isEmpty);
  });

  test('filtre de rang Top 10 et Top 50, combiné à la ligue', () {
    expect(_apply(const CollectionFilter(maxRank: 10)),
        <String>['Carapuce', 'Flambusard']);
    expect(_apply(const CollectionFilter(maxRank: 50)),
        <String>['Carapuce', 'Écayon', 'Flambusard']);
    expect(
      _apply(const CollectionFilter(maxRank: 50, league: League.great)),
      <String>['Écayon'],
    );
    expect(_apply(const CollectionFilter(maxRank: 1)), <String>['Flambusard']);
    expect(rankThresholds, <int?>[null, 1, 10, 50]);
  });

  test('filtre de rang de ligue : rang méta dans la ligue du tag', () {
    final meta = <String, int?>{'Flambusard': 12, 'Écayon': 1, 'Carapuce': null};
    List<String> apply(CollectionFilter f) => _names(filterAndSort(
          _rows,
          f,
          CollectionSort.dex,
          metaRankOf: (e) => meta[e.speciesName],
        ));
    expect(apply(const CollectionFilter(maxMetaRank: 1)), <String>['Écayon']);
    expect(apply(const CollectionFilter(maxMetaRank: 50)),
        <String>['Écayon', 'Flambusard']);
    // Combiné au rang d'IV (Écayon est rang 45 d'IV).
    expect(apply(const CollectionFilter(maxMetaRank: 50, maxRank: 10)),
        <String>['Flambusard']);
    // Sans méta, rien n'est classé : rien ne passe.
    expect(_apply(const CollectionFilter(maxMetaRank: 50)), isEmpty);
    const f = CollectionFilter(maxMetaRank: 10, maxRank: 1);
    expect(f.activeCount, 2);
    final cleared = f.copyWith(clearMaxMetaRank: true);
    expect(cleared.maxMetaRank, isNull);
    expect(cleared.maxRank, 1);
    expect(f.copyWith(maxMetaRank: 1).maxMetaRank, 1);
  });

  test('filtre de type : au moins un des types choisis', () {
    expect(
      _apply(const CollectionFilter(
        types: <PokeType>{PokeType.flying, PokeType.water},
      )),
      <String>['Carapuce', 'Écayon', 'Flambusard'],
    );
  });

  test('filtre d\'attaque immédiate : types ou attaques choisis (OU)', () {
    // Flambusard a enregistré Rapace seulement : Flammèche ne compte plus.
    expect(_apply(const CollectionFilter(fastMoves: <String>{'EMBER'})),
        <String>['Salamèche']);
    expect(
      _apply(const CollectionFilter(fastTypes: <PokeType>{PokeType.water})),
      <String>['Carapuce', 'Écayon'],
    );
    expect(
      _apply(const CollectionFilter(
        fastMoves: <String>{'EMBER'},
        fastTypes: <PokeType>{PokeType.water},
      )),
      <String>['Salamèche', 'Carapuce', 'Écayon'],
    );
    // Rapace est une chargée : elle ne compte pas côté immédiate.
    expect(
      _apply(const CollectionFilter(fastTypes: <PokeType>{PokeType.flying})),
      isEmpty,
    );
  });

  test('filtre d\'attaque chargée, et ET / OU entre immédiate et chargée', () {
    expect(
      _apply(const CollectionFilter(chargedTypes: <PokeType>{PokeType.flying})),
      <String>['Flambusard'],
    );
    expect(
      _apply(const CollectionFilter(chargedMoves: <String>{'BRAVE_BIRD'})),
      <String>['Flambusard'],
    );
    expect(
      _apply(const CollectionFilter(chargedTypes: <PokeType>{PokeType.fire})),
      isEmpty,
    );
    const both = CollectionFilter(
      fastTypes: <PokeType>{PokeType.water},
      chargedTypes: <PokeType>{PokeType.flying},
    );
    expect(both.movesEither, isFalse);
    expect(_apply(both), isEmpty);
    expect(_apply(both.copyWith(movesEither: true)),
        <String>['Carapuce', 'Écayon', 'Flambusard']);
    // Un seul côté rempli : ET et OU donnent la même chose.
    expect(
      _apply(const CollectionFilter(
        fastTypes: <PokeType>{PokeType.water},
        movesEither: true,
      )),
      <String>['Carapuce', 'Écayon'],
    );
    expect(both.activeCount, 2);
    expect(const CollectionFilter(movesEither: true).activeCount, 0);
    final cleared = both.copyWith(
      fastTypes: const <PokeType>{},
      chargedMoves: const <String>{'X'},
      fastMoves: const <String>{},
      chargedTypes: const <PokeType>{},
    );
    expect(cleared.chargedMoves, <String>{'X'});
    expect(cleared.activeCount, 1);
  });

  test('attaques proposées et compte par type, selon la catégorie', () {
    List<String> names(List<Move> moves) =>
        <String>[for (final m in moves) m.nameFr];
    expect(names(moveOptions(_rows, fast: true)),
        <String>['Écume', 'Flammèche']);
    expect(names(moveOptions(_rows, fast: false)), <String>['Rapace']);
    expect(moveTypeCounts(_rows, fast: true),
        <PokeType, int>{PokeType.water: 2, PokeType.fire: 1});
    expect(moveTypeCounts(_rows, fast: false),
        <PokeType, int>{PokeType.flying: 1});
  });

  test('activeCount et copyWith (retrait de la ligue et du rang)', () {
    const f = CollectionFilter(
      league: League.great,
      maxRank: 10,
      types: <PokeType>{PokeType.fire},
    );
    expect(f.activeCount, 3);
    final cleared = f.copyWith(clearLeague: true, clearMaxRank: true);
    expect(cleared.league, isNull);
    expect(cleared.maxRank, isNull);
    expect(cleared.activeCount, 1);
  });

  test('CollectionEntry : aller-retour JSON complet', () {
    const e = CollectionEntry(
      id: 'a',
      speciesName: 'Flambusard',
      iv: Iv(1, 2, 3),
      maxLevel: 50,
      league: League.ultra,
      rank: 1,
      percent: 100,
      cp: 2500,
      level: 39.5,
      fastMove: 'INCINERATE',
      chargedMove2: 'BRAVE_BIRD',
      shadow: ShadowState.purified,
      size: PokeSize.xxl,
      lucky: true,
      shiny: true,
      costume: true,
      favorite: true,
    );
    final back = CollectionEntry.fromJson(e.toJson())!;
    expect(back.costume, isTrue);
    expect(back.toJson(), e.toJson());
    expect(back.isRankOne, isTrue);
    expect(back.moveIds, <String>['INCINERATE', 'BRAVE_BIRD']);
  });

  test('CollectionEntry : options absentes par défaut, entrées invalides', () {
    final minimal = CollectionEntry.fromJson(<String, dynamic>{
      'id': 'b',
      'species': 'X',
      'iv': <int>[0, 0, 0],
      'league': 'great',
      'rank': 12,
    })!;
    expect(minimal.shadow, ShadowState.none);
    expect(minimal.size, PokeSize.none);
    expect(minimal.lucky || minimal.shiny || minimal.costume, isFalse);
    expect(minimal.moveIds, isEmpty);
    expect(
      CollectionEntry.fromJson(<String, dynamic>{
        'id': 'c',
        'species': 'X',
        'iv': <int>[16, 0, 0],
        'league': 'great',
        'rank': 1,
      }),
      isNull,
    );
    expect(
      CollectionEntry.fromJson(<String, dynamic>{
        'id': 'd',
        'species': 'X',
        'iv': <int>[1, 0, 0],
        'league': 'inconnue',
        'rank': 1,
      }),
      isNull,
    );
  });

  test('favoris : filtre « favoris uniquement » et tri favoris d\'abord', () {
    final rows = <CollectionRow>[
      _row('A', 1, <PokeType>[PokeType.fire], League.great, 30),
      _row('B', 2, <PokeType>[PokeType.fire], League.great, 50, favorite: true),
      _row('C', 3, <PokeType>[PokeType.fire], League.great, 10, favorite: true),
    ];
    const only = CollectionFilter(favoritesOnly: true);
    expect(only.activeCount, 1);
    expect(_names(filterAndSort(rows, only, CollectionSort.dex)), <String>['B', 'C']);
    expect(
      _names(filterAndSort(rows, const CollectionFilter(), CollectionSort.favorite)),
      <String>['C', 'B', 'A'],
    );
    expect(only.copyWith(favoritesOnly: false).activeCount, 0);
  });

  test('tri par rang méta : non classés à la fin, puis rang d\'IV', () {
    final meta = <String, int?>{'Flambusard': 12, 'Écayon': 3, 'Carapuce': null};
    expect(
      _names(filterAndSort(
        _rows,
        const CollectionFilter(),
        CollectionSort.metaRank,
        metaRankOf: (e) => meta[e.speciesName],
      )),
      <String>['Écayon', 'Flambusard', 'Carapuce', 'Salamèche'],
    );
    // Sans méta, le tri retombe sur le rang d'IV.
    expect(
      _apply(const CollectionFilter(), CollectionSort.metaRank),
      _apply(const CollectionFilter(), CollectionSort.rank),
    );
  });

  test('recherche par nom : sans accents ni majuscules, combinée aux filtres', () {
    expect(_apply(const CollectionFilter(query: 'flambu')), <String>['Flambusard']);
    expect(_apply(const CollectionFilter(query: 'ECAY')), <String>['Écayon']);
    expect(_apply(const CollectionFilter(query: 'a')),
        <String>['Salamèche', 'Carapuce', 'Écayon', 'Flambusard']);
    expect(_apply(const CollectionFilter(query: '  ')), hasLength(4));
    expect(_apply(const CollectionFilter(query: 'pikachu')), isEmpty);
    expect(
      _apply(const CollectionFilter(query: 'a', league: League.great)),
      <String>['Salamèche', 'Écayon'],
    );
    // La recherche n'est pas comptée parmi les filtres du panneau.
    expect(const CollectionFilter(query: 'a').activeCount, 0);
    expect(const CollectionFilter().copyWith(query: 'sal').query, 'sal');
  });

  test('filtre de coupe : admis dans la coupe et tagués dans sa ligue', () {
    MetaEntry entry(String name, int rank) => MetaEntry(
          rank: rank,
          name: name,
          species: name,
          shadow: false,
          types: const <PokeType>[PokeType.water],
          score: 80,
          fast: const MetaMove(id: 'BUBBLE', nameFr: 'Écume', type: PokeType.water),
          charged: const <MetaMove>[],
          bestMatchups: const <String>[],
          worstMatchups: const <String>[],
        );
    final cup = MetaBoard(
      key: 'spectral-1500',
      label: 'Battle Frontier (Spectral)',
      capLabel: '1500',
      league: League.great,
      entries: <MetaEntry>[entry('Écayon', 3)],
      eligible: const <String>{'Écayon', 'Flambusard', 'Carapuce'},
    );
    // Salamèche n'est pas admis ; Flambusard et Carapuce sont tagués dans
    // une autre ligue.
    expect(_apply(CollectionFilter(cup: cup)), <String>['Écayon']);
    expect(CollectionFilter(cup: cup).activeCount, 1);
    expect(CollectionFilter(cup: cup).copyWith(clearCup: true).cup, isNull);
    // Avec une coupe, le rang de ligue est celui de la méta de la coupe.
    expect(
      _apply(CollectionFilter(cup: cup, maxMetaRank: 10)),
      <String>['Écayon'],
    );
    expect(_apply(CollectionFilter(cup: cup, maxMetaRank: 1)), isEmpty);
  });
}
