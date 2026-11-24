import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/collection.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/rank_table.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';

const _ember = Move(id: 'EMBER', nameFr: 'Flammèche', type: PokeType.fire, isFast: true);
const _bubble = Move(id: 'BUBBLE', nameFr: 'Écume', type: PokeType.water, isFast: true);
const _braveBird = Move(id: 'BRAVE_BIRD', nameFr: 'Rapace', type: PokeType.flying, isFast: false);

CollectionRow _row(
  String name,
  int dex,
  List<PokeType> types,
  int rank,
  List<Move> moves,
) {
  const iv = Iv(15, 15, 15);
  return CollectionRow(
    entry: CollectionEntry(id: name, speciesName: name, iv: iv, maxLevel: 51),
    species: Species(
      dex: dex,
      nameFr: name,
      base: const BaseStats(100, 100, 100),
      types: types,
    ),
    rank: RankEntry(
      rank: rank,
      level: 40,
      cp: 1500,
      iv: iv,
      statProduct: 1,
      percent: 90,
    ),
    moves: moves,
  );
}

final _rows = <CollectionRow>[
  _row('Flambusard', 663, <PokeType>[PokeType.fire, PokeType.flying], 120,
      <Move>[_ember, _braveBird]),
  _row('Carapuce', 7, <PokeType>[PokeType.water], 8, <Move>[_bubble]),
  _row('Écayon', 550, <PokeType>[PokeType.water], 45, <Move>[_bubble]),
  _row('Salamèche', 4, <PokeType>[PokeType.fire], 600, <Move>[_ember]),
];

List<String> _names(List<CollectionRow> rows) =>
    <String>[for (final r in rows) r.species.nameFr];

void main() {
  test('tri par rang, par Pokédex, par nom (accents ignorés) et par type', () {
    const all = CollectionFilter();
    expect(
      _names(filterAndSort(_rows, all, CollectionSort.rank)),
      <String>['Carapuce', 'Écayon', 'Flambusard', 'Salamèche'],
    );
    expect(
      _names(filterAndSort(_rows, all, CollectionSort.dex)),
      <String>['Salamèche', 'Carapuce', 'Écayon', 'Flambusard'],
    );
    expect(
      _names(filterAndSort(_rows, all, CollectionSort.name)),
      <String>['Carapuce', 'Écayon', 'Flambusard', 'Salamèche'],
    );
    expect(
      _names(filterAndSort(_rows, all, CollectionSort.type)),
      <String>['Salamèche', 'Flambusard', 'Carapuce', 'Écayon'],
    );
  });

  test('filtre de rang', () {
    final rows = filterAndSort(
      _rows,
      const CollectionFilter(maxRank: 50),
      CollectionSort.rank,
    );
    expect(_names(rows), <String>['Carapuce', 'Écayon']);
  });

  test('filtre de type : au moins un des types choisis', () {
    final rows = filterAndSort(
      _rows,
      const CollectionFilter(types: <PokeType>{PokeType.flying, PokeType.water}),
      CollectionSort.dex,
    );
    expect(_names(rows), <String>['Carapuce', 'Écayon', 'Flambusard']);
  });

  test('filtres d\'attaque par type et par nom, combinés aux autres', () {
    expect(
      _names(filterAndSort(
        _rows,
        const CollectionFilter(moveTypes: <PokeType>{PokeType.flying}),
        CollectionSort.dex,
      )),
      <String>['Flambusard'],
    );
    expect(
      _names(filterAndSort(
        _rows,
        const CollectionFilter(moveQuery: 'flammeche'),
        CollectionSort.dex,
      )),
      <String>['Salamèche', 'Flambusard'],
    );
    expect(
      _names(filterAndSort(
        _rows,
        const CollectionFilter(moveQuery: 'Flammèche', maxRank: 500),
        CollectionSort.dex,
      )),
      <String>['Flambusard'],
    );
  });

  test('activeCount compte les filtres actifs, copyWith retire le rang', () {
    const f = CollectionFilter(
      maxRank: 10,
      types: <PokeType>{PokeType.fire},
      moveQuery: 'x',
    );
    expect(f.activeCount, 3);
    expect(f.copyWith(clearMaxRank: true).maxRank, isNull);
    expect(f.copyWith(clearMaxRank: true).activeCount, 2);
  });

  test('CollectionEntry : aller-retour JSON et rejet des entrées invalides', () {
    const e = CollectionEntry(
      id: 'a',
      speciesName: 'Flambusard',
      iv: Iv(1, 2, 3),
      maxLevel: 50,
    );
    final back = CollectionEntry.fromJson(e.toJson())!;
    expect(back.sameAs(e), isTrue);
    expect(back.maxLevel, 50);
    expect(
      CollectionEntry.fromJson(<String, dynamic>{
        'id': 'b',
        'species': 'X',
        'iv': <int>[16, 0, 0],
      }),
      isNull,
    );
    expect(CollectionEntry.fromJson('nimporte'), isNull);
  });
}
