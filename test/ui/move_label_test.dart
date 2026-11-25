import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/ui/move_label.dart';

void main() {
  test('les effets disent qui change et de combien', () {
    expect(
      effectLabels(const StatChange(target: StatTarget.self, attack: -2)),
      <String>['Ton attaque −2'],
    );
    expect(
      effectLabels(const StatChange(target: StatTarget.self, attack: 1, defense: 1)),
      <String>['Ton attaque +1', 'Ta défense +1'],
    );
    expect(
      effectLabels(const StatChange(target: StatTarget.opponent, defense: -1)),
      <String>['Défense adverse −1'],
    );
    expect(
      effectLabels(const StatChange(target: StatTarget.opponent, attack: -1)),
      <String>['Attaque adverse −1'],
    );
  });

  test('un effet aléatoire montre sa probabilité', () {
    expect(
      effectLabels(
        const StatChange(target: StatTarget.self, attack: 1, chance: 0.3),
      ),
      <String>['Ton attaque +1 (30 % de chance)'],
    );
    expect(
      effectLabels(
        const StatChange(target: StatTarget.opponent, defense: -1, chance: 0.125),
      ),
      <String>['Défense adverse −1 (12,5 % de chance)'],
    );
  });
}
