import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/collection.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/collection_controller.dart';

const _flambusard = Species(
  dex: 663,
  nameFr: 'Flambusard',
  base: BaseStats(176, 155, 186),
  types: <PokeType>[PokeType.fire, PokeType.flying],
  fastMoves: <String>['INCINERATE'],
);

CollectionController _controller(SettingsStore store) => CollectionController(
      repository: SpeciesRepository(const <Species>[_flambusard]),
      moves: MoveBook(const <Move>[
        Move(
          id: 'INCINERATE',
          nameFr: 'Calcination',
          type: PokeType.fire,
          isFast: true,
        ),
      ]),
      store: store,
    );

void main() {
  test('un même Pokémon n\'est enregistré qu\'une fois', () {
    final c = _controller(MemorySettingsStore());
    expect(c.add(_flambusard, const Iv(15, 15, 15), 51), isTrue);
    expect(c.add(_flambusard, const Iv(15, 15, 15), 51), isFalse);
    expect(c.add(_flambusard, const Iv(15, 15, 15), 50), isTrue);
    expect(c.entries.length, 2);
    expect(c.ownedSpecies, <String>{'Flambusard'});
  });

  test('le rang suit la ligue affichée', () {
    final c = _controller(MemorySettingsStore())
      ..add(_flambusard, const Iv(15, 15, 15), 51);
    expect(c.visibleRows.single.rank.rank, 2246);
    c.setLeague(League.ultra);
    expect(c.visibleRows.single.rank.rank, 21);
    c.setLeague(League.little);
    expect(c.visibleRows.single.rank.rank, 550);
    c.setLeague(League.master);
    expect(c.visibleRows.single.rank.rank, 1);
  });

  test('la collection est enregistrée puis rechargée', () async {
    final store = MemorySettingsStore();
    _controller(store).add(_flambusard, const Iv(0, 14, 2), 50);
    final again = _controller(store);
    await again.load();
    expect(again.entries.single.iv, const Iv(0, 14, 2));
    expect(again.entries.single.maxLevel, 50);
  });

  test('retirer puis annuler remet le Pokémon', () {
    final c = _controller(MemorySettingsStore())
      ..add(_flambusard, const Iv(15, 15, 15), 51);
    final entry = c.entries.single;
    c.remove(entry.id);
    expect(c.entries, isEmpty);
    c.restore(entry);
    expect(c.entries.single.id, entry.id);
  });

  test('les filtres s\'appliquent aux lignes visibles', () {
    final c = _controller(MemorySettingsStore())
      ..add(_flambusard, const Iv(15, 15, 15), 51)
      ..setFilter(const CollectionFilter(types: <PokeType>{PokeType.water}));
    expect(c.visibleRows, isEmpty);
    expect(c.total, 1);
    c.setFilter(const CollectionFilter(moveQuery: 'calcin'));
    expect(c.visibleRows.length, 1);
  });
}
