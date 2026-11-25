import 'package:flutter_test/flutter_test.dart';
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
}
