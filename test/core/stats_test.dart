import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/stats.dart';

void main() {
  const flambusard = BaseStats(176, 155, 186);
  const maxIv = Iv(15, 15, 15);

  test('computeCp donne 2493 pour un Flambusard 15/15/15 niveau 50', () {
    expect(computeCp(flambusard, maxIv, 50), 2493);
  });

  test('computeHp donne 168 pour un Flambusard 15/15/15 niveau 50', () {
    expect(computeHp(flambusard, maxIv, 50), 168);
  });

  test('statProduct reste à 0,05 % de 3851770 pour ce Flambusard', () {
    expect(
      statProduct(flambusard, maxIv, 50),
      closeTo(3851770, 3851770 * 0.0005),
    );
  });

  test('computeCp ne descend jamais sous 10', () {
    expect(computeCp(const BaseStats(1, 1, 1), const Iv(0, 0, 0), 1), 10);
  });

  test('cpm couvre les niveaux 1 à 51 par demi-pas', () {
    expect(cpm(1), closeTo(0.094, 1e-6));
    expect(cpm(50.5), closeTo(0.8528, 1e-4));
    expect(cpm(51), closeTo(0.8653, 1e-4));
  });

  test('cpm refuse un niveau hors de la table', () {
    expect(() => cpm(51.5), throwsArgumentError);
    expect(() => cpm(0.5), throwsArgumentError);
    expect(() => cpm(10.3), throwsArgumentError);
  });
}
