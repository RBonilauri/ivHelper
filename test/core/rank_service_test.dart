import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/rank_service.dart';
import 'package:ivhelper/core/stats.dart';

void main() {
  const flambusard = BaseStats(176, 155, 186);
  const maxIv = Iv(15, 15, 15);

  test('rankIv donne rang 21 en hyper et 2246 en super au niveau max 51', () {
    final result = rankIv(flambusard, maxIv);
    expect(result.ultra.mine.rank, 21);
    expect(result.great.mine.rank, 2246);
  });

  test('les plafonds de PC sont 1500 en super et 2500 en hyper', () {
    final result = rankIv(flambusard, maxIv);
    expect(result.great.cpCap, 1500);
    expect(result.ultra.cpCap, 2500);
    expect(result.little.cpCap, 500);
    expect(result.master.cpCap, 10000);
  });

  test('top(10) renvoie les dix premiers rangs dans l\'ordre', () {
    final top = rankIv(flambusard, maxIv).ultra.top(10);
    expect(top.map((e) => e.rank), <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  test('au niveau max 50, le 15/15/15 est rang 1 en hyper', () {
    final result = rankIv(flambusard, maxIv, maxLevel: 50);
    expect(result.ultra.mine.rank, 1);
    expect(result.ultra.mine.level, 50);
  });

  test('mini : le 15/15/15 est rang 550 (niveau 8, 497 PC), rang 1 0/14/2',
      () {
    final little = rankIv(flambusard, maxIv).little;
    expect(little.mine.rank, 550);
    expect(little.mine.level, 8);
    expect(little.mine.cp, 497);
    expect(little.table.entries.first.iv, const Iv(0, 14, 2));
    expect(little.table.entries.first.cp, 500);
  });

  test('master : le 15/15/15 est rang 1 au niveau 51 (2522 PC)', () {
    final master = rankIv(flambusard, maxIv).master;
    expect(master.mine.rank, 1);
    expect(master.mine.level, 51);
    expect(master.mine.cp, 2522);
    expect(master.table.entries[1].iv, const Iv(15, 15, 14));
  });
}
