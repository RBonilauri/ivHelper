import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/rank_service.dart';
import 'package:ivhelper/core/stat_line.dart';
import 'package:ivhelper/core/stats.dart';

void main() {
  const flambusard = BaseStats(176, 155, 186);

  test('statLine d\'un 15/15/15 niveau 50 donne les stats réelles', () {
    final mine = rankIv(flambusard, const Iv(15, 15, 15)).ultra.mine;
    final line = statLine(flambusard, mine);
    expect(line.atk, closeTo(160.49, 0.01));
    expect(line.def, closeTo(142.85, 0.01));
    expect(line.hp, 168);
    expect(line.product, closeTo(3851770, 1));
  });

  test('statLine du rang 1 hyper reprend le produit de la table', () {
    final first = rankIv(flambusard, const Iv(15, 15, 15)).ultra.top(1).first;
    final line = statLine(flambusard, first);
    expect(line.hp, 169);
    expect(line.product, closeTo(first.statProduct, 0.001));
  });
}
