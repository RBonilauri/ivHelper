import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/collection.dart';
import 'package:ivhelper/core/power_up.dart';

void main() {
  // Totaux vérifiés par des calculateurs indépendants (Dittobase,
  // Pokémon GO Hub, Bulbapedia).
  test('du niveau 20 au 50 : normal, chanceux, obscur, purifié', () {
    void check(PowerUpCost? c, int dust, int candy, int xl) {
      expect(c, isNotNull);
      expect(<int>[c!.stardust, c.candy, c.xlCandy], <int>[dust, candy, xl]);
      expect(c.powerUps, 60);
    }

    check(powerUpCost(20, 50), 475000, 248, 296);
    check(powerUpCost(20, 50, lucky: true), 237500, 248, 296);
    check(powerUpCost(20, 50, shadow: ShadowState.shadow), 570000, 312, 360);
    check(powerUpCost(20, 50, shadow: ShadowState.purified), 427500, 238, 272);
    check(
      powerUpCost(20, 50, lucky: true, shadow: ShadowState.purified),
      213750,
      238,
      272,
    );
  });

  test('repères connus : 1 → 40 et 40 → 50', () {
    final low = powerUpCost(1, 40)!;
    expect(<int>[low.stardust, low.candy, low.xlCandy], <int>[270000, 304, 0]);
    final high = powerUpCost(40, 50)!;
    expect(<int>[high.stardust, high.candy, high.xlCandy], <int>[250000, 0, 296]);
  });

  test('un pas : 30 → 30,5 coûte 5000 poussières et 4 bonbons', () {
    final step = powerUpCost(30, 30.5)!;
    expect(<int>[step.stardust, step.candy, step.xlCandy, step.powerUps],
        <int>[5000, 4, 0, 1]);
  });

  test('même niveau : rien ; niveau visé plus bas : impossible', () {
    final none = powerUpCost(25, 25)!;
    expect(none.powerUps, 0);
    expect(none.stardust, 0);
    expect(powerUpCost(30, 20), isNull);
  });

  test('le niveau 51 (meilleur ami) ne coûte rien de plus que le 50', () {
    final to51 = powerUpCost(40, 51)!;
    expect(to51.stardust, 250000);
    expect(to51.xlCandy, 296);
  });
}
