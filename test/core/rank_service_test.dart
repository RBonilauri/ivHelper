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
}
