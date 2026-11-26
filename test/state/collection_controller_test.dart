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
  chargedMoves: <String>['BRAVE_BIRD'],
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
        Move(
          id: 'BRAVE_BIRD',
          nameFr: 'Rapace',
          type: PokeType.flying,
          isFast: false,
        ),
      ]),
      store: store,
    );

const _max = Iv(15, 15, 15);

void main() {
  test('le rang de la ligue choisie est calculé à l\'enregistrement', () {
    final c = _controller(MemorySettingsStore());
    final great = c.add(_flambusard, _max, 51, const SaveOptions(league: League.great));
    final ultra = c.add(_flambusard, _max, 51, const SaveOptions(league: League.ultra));
    final little = c.add(_flambusard, _max, 51, const SaveOptions(league: League.little));
    final master = c.add(_flambusard, _max, 51, const SaveOptions(league: League.master));
    expect(great.rank, 2246);
    expect(ultra.rank, 21);
    expect(little.rank, 550);
    expect(little.cp, 497);
    expect(little.level, 8);
    expect(master.rank, 1);
    expect(master.isRankOne, isTrue);
  });

  test('les doublons sont autorisés', () {
    final c = _controller(MemorySettingsStore())
      ..add(_flambusard, _max, 51, const SaveOptions(league: League.great))
      ..add(_flambusard, _max, 51, const SaveOptions(league: League.great));
    expect(c.entries.length, 2);
    expect(c.entries[0].id, isNot(c.entries[1].id));
  });

  test('options enregistrées ; attaque que l\'espèce n\'apprend pas ignorée',
      () {
    final c = _controller(MemorySettingsStore());
    final e = c.add(
      _flambusard,
      _max,
      51,
      const SaveOptions(
        league: League.ultra,
        fastMove: 'INCINERATE',
        chargedMove1: 'BRAVE_BIRD',
        chargedMove2: 'HYDRO_PUMP',
        shadow: ShadowState.shadow,
        size: PokeSize.xl,
        lucky: true,
        shiny: true,
      ),
    );
    expect(e.moveIds, <String>['INCINERATE', 'BRAVE_BIRD']);
    expect(e.shadow, ShadowState.shadow);
    expect(e.size, PokeSize.xl);
    expect(e.lucky && e.shiny, isTrue);
    expect(c.rowOf(e.id)!.recordedMoves.map((m) => m.nameFr),
        <String>['Calcination', 'Rapace']);
  });

  test('modifier : options remplacées, rang recalculé', () {
    final c = _controller(MemorySettingsStore());
    final e = c.add(_flambusard, _max, 51, const SaveOptions(league: League.great));
    c.update(e.id, const SaveOptions(league: League.great, shiny: true));
    expect(c.entries.single.shiny, isTrue);
    expect(c.entries.single.rank, 2246);
    c.update(e.id, const SaveOptions(league: League.ultra));
    expect(c.entries.single.league, League.ultra);
    expect(c.entries.single.rank, 21);
    expect(c.entries.single.shiny, isFalse);
  });

  test('la collection est enregistrée puis rechargée', () async {
    final store = MemorySettingsStore();
    _controller(store).add(
      _flambusard,
      const Iv(0, 14, 2),
      50,
      const SaveOptions(league: League.little, size: PokeSize.xxs),
    );
    final again = _controller(store);
    await again.load();
    final e = again.entries.single;
    expect(e.iv, const Iv(0, 14, 2));
    expect(e.maxLevel, 50);
    expect(e.league, League.little);
    expect(e.size, PokeSize.xxs);
  });

  test('filtres, suppression et affichage', () {
    final c = _controller(MemorySettingsStore());
    final e = c.add(_flambusard, _max, 51, const SaveOptions(league: League.ultra));
    c.setFilter(const CollectionFilter(league: League.great));
    expect(c.visibleRows, isEmpty);
    expect(c.total, 1);
    c.setFilter(const CollectionFilter(league: League.ultra, maxRank: 50));
    expect(c.visibleRows.length, 1);
    c.setView(CollectionView.grid);
    expect(c.view, CollectionView.grid);
    c.remove(e.id);
    expect(c.entries, isEmpty);
  });

  test('les entrées de l\'ancien format passent en ligue super avec leur rang',
      () async {
    final store = MemorySettingsStore();
    await store.writeCollection(
      '[{"id":"x","species":"Flambusard","iv":[15,15,15],"maxLevel":51}]',
    );
    final c = _controller(store);
    await c.load();
    final e = c.entries.single;
    expect(e.id, 'x');
    expect(e.league, League.great);
    expect(e.rank, 2246);
    expect(await store.readCollection(), contains('"league":"great"'));
  });

  test('costume enregistré ; seconde chargée identique à la première retirée',
      () {
    final c = _controller(MemorySettingsStore());
    final e = c.add(
      _flambusard,
      _max,
      51,
      const SaveOptions(
        league: League.great,
        chargedMove1: 'BRAVE_BIRD',
        chargedMove2: 'BRAVE_BIRD',
        costume: true,
      ),
    );
    expect(e.costume, isTrue);
    expect(e.chargedMove1, 'BRAVE_BIRD');
    expect(e.chargedMove2, isNull);
  });

  test('favori : bascule, survit à une modification et à un rechargement', () async {
    final store = MemorySettingsStore();
    final c = _controller(store);
    final e = c.add(_flambusard, _max, 51, const SaveOptions(league: League.great));
    expect(c.entries.single.favorite, isFalse);
    c.toggleFavorite(e.id);
    expect(c.entries.single.favorite, isTrue);
    c.update(e.id, const SaveOptions(league: League.great, lucky: true));
    expect(c.entries.single.favorite, isTrue);
    c.update(e.id, const SaveOptions(league: League.ultra));
    expect(c.entries.single.favorite, isTrue);
    await Future<void>.delayed(Duration.zero);
    final reloaded = _controller(store);
    await reloaded.load();
    expect(reloaded.entries.single.favorite, isTrue);
    reloaded.toggleFavorite(e.id);
    expect(reloaded.entries.single.favorite, isFalse);
  });

  test('rang recalculé au chargement, jamais figé, et réenregistré', () async {
    final store = MemorySettingsStore();
    // Valeurs périmées (données d'une ancienne version, par exemple).
    await store.writeCollection(
      '[{"id":"a","species":"Flambusard","iv":[15,15,15],"maxLevel":51,'
      '"league":"great","rank":999,"percent":50,"cp":1,"level":1}]',
    );
    final c = _controller(store);
    await c.load();
    final e = c.entries.single;
    expect(e.rank, 2246);
    expect(e.cp, 1480);
    expect(e.level, 23.5);
    expect(e.percent, greaterThan(50));
    await Future<void>.delayed(Duration.zero);
    expect(await store.readCollection(), contains('"rank":2246'));
  });
}
