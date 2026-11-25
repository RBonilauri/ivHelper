import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/rank_table.dart';
import 'package:ivhelper/core/search_string.dart';
import 'package:ivhelper/core/stats.dart';

void main() {
  const flambusard = BaseStats(176, 155, 186);

  test('les IV sont regroupés comme dans la recherche du jeu', () {
    expect(
      <int>[for (var iv = 0; iv <= 15; iv++) ivBucket(iv)],
      <int>[0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4],
    );
  });

  test('pour une espèce : bornes couvrant le top N, plafond de PC', () {
    // Valeurs vérifiées par un calcul indépendant (Python).
    final great = buildRankTable(flambusard, cpCap: 1500, maxLevel: 50);
    final top10 = speciesSearch(great, name: 'Flambusard', top: 10, cpCap: 1500);
    expect(top10.text, '+flambusard&0-1attaque&3-4défense&2-4PV&PC-1500');
    expect(top10.kept, 300);
    expect(top10.total, 4096);

    // Une stat sans contrainte disparaît de la chaîne.
    final top100 = speciesSearch(great, name: 'Flambusard', top: 100, cpCap: 1500);
    expect(top100.text, '+flambusard&0-2attaque&1-4défense&PC-1500');
    expect(top100.kept, 2640);

    final ultra = buildRankTable(flambusard, cpCap: 2500, maxLevel: 50);
    expect(
      speciesSearch(ultra, name: 'Flambusard', top: 10, cpCap: 2500).text,
      '+flambusard&3-4attaque&3-4défense&3-4PV&PC-2500',
    );
  });

  test('ligue Master : pas de plafond de PC', () {
    final master = buildRankTable(flambusard, cpCap: 10000, maxLevel: 50);
    expect(
      speciesSearch(master, name: 'Flambusard', top: 1, cpCap: null).text,
      '+flambusard&4attaque&4défense&4PV',
    );
  });

  test('le nom de famille garde le nom de base de l\'espèce', () {
    expect(familyName("Raichu d'Alola"), 'raichu');
    expect(familyName('Morphéo (Sunny)'), 'morphéo');
    expect(familyName('Flambusard'), 'flambusard');
  });

  test('recherches prêtes à l\'emploi', () {
    final texts = <String>[for (final p in searchPresets) p.text];
    expect(texts, contains('0-1attaque&3-4défense&3-4PV&PC-1500'));
    expect(texts, contains('0-1attaque&3-4défense&3-4PV&PC-2500'));
    expect(texts, contains('4*'));
    expect(texts, contains('0attaque&0défense&0PV'));
    for (final p in searchPresets) {
      expect(p.title, isNotEmpty);
      expect(p.description, isNotEmpty);
    }
  });
}
