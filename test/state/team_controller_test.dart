import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/team_controller.dart';

const _flambusard = Species(
  dex: 663,
  nameFr: 'Flambusard',
  base: BaseStats(176, 155, 186),
  types: <PokeType>[PokeType.fire, PokeType.flying],
  fastMoves: <String>['INCINERATE'],
  chargedMoves: <String>['BRAVE_BIRD'],
);

final _moves = MoveBook(const <Move>[
  Move(id: 'INCINERATE', nameFr: 'Calcination', type: PokeType.fire, isFast: true),
  Move(id: 'BRAVE_BIRD', nameFr: 'Rapace', type: PokeType.flying, isFast: false),
]);

TeamController _controller(SettingsStore store) => TeamController(
      repository: SpeciesRepository(const <Species>[_flambusard]),
      moves: _moves,
      store: store,
    );

void main() {
  test('choisir une espèce remet ses attaques à zéro', () {
    final c = _controller(MemorySettingsStore())
      ..setSpecies(0, _flambusard)
      ..setFast(0, _moves['INCINERATE']);
    expect(c.slots[0].moves.single.id, 'INCINERATE');
    c.setSpecies(0, _flambusard);
    expect(c.slots[0].moves, isEmpty);
  });

  test('les options d\'attaque viennent de l\'espèce', () {
    final c = _controller(MemorySettingsStore())..setSpecies(1, _flambusard);
    expect(c.fastOptions(1).map((m) => m.id), <String>['INCINERATE']);
    expect(c.chargedOptions(1).map((m) => m.id), <String>['BRAVE_BIRD']);
    expect(c.fastOptions(0), isEmpty);
  });

  test('l\'équipe est enregistrée puis rechargée', () async {
    final store = MemorySettingsStore();
    _controller(store)
      ..setSpecies(2, _flambusard)
      ..setFast(2, _moves['INCINERATE'])
      ..setCharged(2, 1, _moves['BRAVE_BIRD']);
    final again = _controller(store);
    await again.load();
    final slot = again.slots[2];
    expect(slot.species?.nameFr, 'Flambusard');
    expect(slot.fast?.id, 'INCINERATE');
    expect(slot.charged1?.id, 'BRAVE_BIRD');
    expect(slot.charged2, isNull);
    expect(again.offenseOf(2)!.strugglesAgainst, <PokeType>[PokeType.rock]);
  });

  test('une sauvegarde illisible est ignorée', () async {
    final store = MemorySettingsStore();
    await store.writeTeam('pas du json');
    final c = _controller(store);
    await c.load();
    expect(c.slots.every((s) => s.species == null), isTrue);
  });

  test('une attaque chargée ne peut pas être prise deux fois', () {
    final c = _controller(MemorySettingsStore())
      ..setSpecies(0, _flambusard)
      ..setCharged(0, 1, _moves['BRAVE_BIRD']);
    expect(c.chargedOptionsFor(0, 2), isEmpty);
    expect(c.chargedOptionsFor(0, 1).map((m) => m.id), <String>['BRAVE_BIRD']);
    c.setCharged(0, 2, _moves['BRAVE_BIRD']);
    expect(c.slots[0].charged2, isNull);
  });

  test('un Pokémon de la collection n\'est importé qu\'une fois', () async {
    final store = MemorySettingsStore();
    final c = _controller(store);
    expect(
      c.importFromCollection(0, 'e1', _flambusard, fastId: 'INCINERATE',
          chargedIds: <String>['BRAVE_BIRD', 'BRAVE_BIRD']),
      isTrue,
    );
    expect(c.slots[0].charged1?.id, 'BRAVE_BIRD');
    expect(c.slots[0].charged2, isNull);
    expect(c.importFromCollection(1, 'e1', _flambusard), isFalse);
    expect(c.slots[1].species, isNull);
    expect(c.importFromCollection(0, 'e1', _flambusard), isTrue);
    expect(c.importedIds(), <String>{'e1'});
    expect(c.importedIds(except: 0), isEmpty);
    c.setFast(0, null);
    expect(c.slots[0].collectionId, 'e1');
    final again = _controller(store);
    await again.load();
    expect(again.slots[0].collectionId, 'e1');
    again.setSpecies(0, _flambusard);
    expect(again.slots[0].collectionId, isNull);
  });
}
