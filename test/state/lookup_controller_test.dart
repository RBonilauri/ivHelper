import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/state/lookup_controller.dart';

SpeciesRepository _repository() => SpeciesRepository(const <Species>[
      Species(dex: 663, nameFr: 'Flambusard', base: BaseStats(176, 155, 186)),
      Species(dex: 661, nameFr: 'Passerouge', base: BaseStats(95, 80, 128)),
    ]);

void main() {
  test('au départ aucune espèce ni résultat, IV à 15/15/15 et niveau max 51',
      () {
    final c = LookupController(_repository());
    expect(c.species, isNull);
    expect(c.result, isNull);
    expect(c.iv, const Iv(15, 15, 15));
    expect(c.maxLevel, 51);
  });

  test('setQuery avec un nom connu calcule les résultats', () {
    final c = LookupController(_repository())..setQuery('Flambusard');
    expect(c.species?.dex, 663);
    expect(c.result?.ultra.mine.rank, 21);
    expect(c.result?.great.mine.rank, 2246);
  });

  test('setQuery accepte un numéro de Pokédex', () {
    final c = LookupController(_repository())..setQuery('663');
    expect(c.species?.nameFr, 'Flambusard');
  });

  test('setQuery avec un nom inconnu vide les résultats et le signale', () {
    final c = LookupController(_repository())
      ..setQuery('Flambusard')
      ..setQuery('Zorglub');
    expect(c.species, isNull);
    expect(c.result, isNull);
    expect(c.hasUnknownQuery, isTrue);
  });

  test('une saisie vide n\'est pas une espèce inconnue', () {
    final c = LookupController(_repository())..setQuery('');
    expect(c.hasUnknownQuery, isFalse);
  });

  test('setIv recalcule le rang', () {
    final c = LookupController(_repository())
      ..setQuery('Flambusard')
      ..setIv(const Iv(13, 15, 15));
    expect(c.result?.ultra.mine.rank, 1);
  });

  test('setMaxLevel 50 place le 15/15/15 au rang 1 en hyper', () {
    final c = LookupController(_repository())
      ..setQuery('Flambusard')
      ..setMaxLevel(50);
    expect(c.result?.ultra.mine.rank, 1);
  });

  test('selectSpecies remplit la saisie avec le nom choisi', () {
    final repo = _repository();
    final c = LookupController(repo)..selectSpecies(repo.all.first);
    expect(c.query, 'Flambusard');
    expect(c.result, isNotNull);
  });

  test('suggestions propose les noms proches de la saisie', () {
    final c = LookupController(_repository())..setQuery('Pass');
    expect(c.suggestions.map((s) => s.nameFr), contains('Passerouge'));
  });
}
