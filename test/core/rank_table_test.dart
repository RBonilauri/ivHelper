import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/rank_table.dart';
import 'package:ivhelper/core/stats.dart';

void main() {
  const flambusard = BaseStats(176, 155, 186);
  final ultra = buildRankTable(flambusard, cpCap: 2500);
  final great = buildRankTable(flambusard, cpCap: 1500);

  test('la table contient les 4096 combinaisons, rangs 1 à 4096 sans trou', () {
    expect(ultra.entries.length, 4096);
    final ranks = ultra.entries.map((e) => e.rank).toList()..sort();
    expect(ranks, List<int>.generate(4096, (i) => i + 1));
  });

  test('hyper : le 15/15/15 est rang 21 au niveau 50 avec 2493 PC', () {
    final e = ultra.entryFor(const Iv(15, 15, 15));
    expect(e.rank, 21);
    expect(e.level, 50);
    expect(e.cp, 2493);
    expect(e.percent, closeTo(99.28, 0.01));
  });

  test('hyper : les rangs 1 et 2 sont 13/15/15 et 13/15/14 au niveau 51', () {
    final first = ultra.entries[0];
    final second = ultra.entries[1];
    expect(first.iv, const Iv(13, 15, 15));
    expect(second.iv, const Iv(13, 15, 14));
    expect(first.level, 51);
    expect(second.level, 51);
    expect(first.percent, 100);
    expect(second.percent, closeTo(100, 0.0001));
  });

  test('super : le 15/15/15 est rang 2246 au niveau 23,5 avec 1480 PC', () {
    final e = great.entryFor(const Iv(15, 15, 15));
    expect(e.rank, 2246);
    expect(e.level, 23.5);
    expect(e.cp, 1480);
  });

  test('aucun PC ne dépasse le plafond de la ligue', () {
    expect(great.entries.every((e) => e.cp <= 1500), isTrue);
    expect(ultra.entries.every((e) => e.cp <= 2500), isTrue);
  });

  test('un niveau maximal de 50 écarte les niveaux 50,5 et 51', () {
    final capped = buildRankTable(flambusard, cpCap: 2500, maxLevel: 50);
    expect(capped.entries.every((e) => e.level <= 50), isTrue);
  });

  test('minIv 10 ne classe que les 1331 combinaisons 10 à 15', () {
    final t = buildRankTable(flambusard, cpCap: 1500, minIv: 10);
    expect(t.entries.length, 1331);
    expect(t.entries.first.rank, 1);
    expect(t.entries.first.percent, 100);
    expect(
      t.entries.every(
        (e) => e.iv.atk >= 10 && e.iv.def >= 10 && e.iv.sta >= 10,
      ),
      isTrue,
    );
  });
}
