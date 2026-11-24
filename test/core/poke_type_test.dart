import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/poke_type.dart';

void main() {
  test('multiplicateurs de Pokémon GO : 1,6, 0,625 et 0,390625', () {
    expect(singleEffectiveness(PokeType.fire, PokeType.grass), 1.6);
    expect(singleEffectiveness(PokeType.fire, PokeType.water), 0.625);
    expect(singleEffectiveness(PokeType.ground, PokeType.flying), 0.390625);
    expect(singleEffectiveness(PokeType.normal, PokeType.normal), 1);
  });

  test('les multiplicateurs se cumulent sur un double type', () {
    expect(
      effectiveness(PokeType.fire, <PokeType>[PokeType.grass, PokeType.steel]),
      closeTo(2.56, 1e-9),
    );
    expect(
      effectiveness(
        PokeType.fighting,
        <PokeType>[PokeType.normal, PokeType.ghost],
      ),
      closeTo(0.625, 1e-9),
    );
  });

  test('Plante : forte contre Eau, Sol, Roche ; faible face à 5 types', () {
    expect(
      strongAgainst(PokeType.grass),
      <PokeType>[PokeType.water, PokeType.ground, PokeType.rock],
    );
    expect(
      weakTo(PokeType.grass).toSet(),
      <PokeType>{
        PokeType.fire,
        PokeType.ice,
        PokeType.poison,
        PokeType.flying,
        PokeType.bug,
      },
    );
  });

  test('immunités comptées comme résistances', () {
    expect(resists(PokeType.fairy), contains(PokeType.dragon));
    expect(weakAgainst(PokeType.dragon), <PokeType>[PokeType.steel, PokeType.fairy]);
  });

  test('fromId retrouve chaque type et refuse un identifiant inconnu', () {
    for (final t in PokeType.values) {
      expect(PokeType.fromId(t.id), t);
    }
    expect(PokeType.fromId('shadow'), isNull);
  });
}
