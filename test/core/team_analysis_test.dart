import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/team_analysis.dart';

const _incinerate = Move(
  id: 'INCINERATE',
  nameFr: 'Calcination',
  type: PokeType.fire,
  isFast: true,
);
const _braveBird = Move(
  id: 'BRAVE_BIRD',
  nameFr: 'Rapace',
  type: PokeType.flying,
  isFast: false,
);

void main() {
  final talonflame = DefenseProfile(<PokeType>[PokeType.fire, PokeType.flying]);

  test('Feu/Vol : double faiblesse Roche, faiblesse Eau et Électrik', () {
    final w = talonflame.weaknesses;
    expect(w.first.type, PokeType.rock);
    expect(w.first.factor, closeTo(2.56, 1e-9));
    expect(
      w.map((e) => e.type).toSet(),
      <PokeType>{PokeType.rock, PokeType.water, PokeType.electric},
    );
  });

  test('Feu/Vol : Plante et Insecte en double résistance, Sol à 0,625', () {
    final r = {for (final e in talonflame.resistances) e.type: e.factor};
    expect(r[PokeType.grass], closeTo(0.390625, 1e-9));
    expect(r[PokeType.bug], closeTo(0.390625, 1e-9));
    expect(r[PokeType.ground], closeTo(0.625, 1e-9));
    expect(r[PokeType.fairy], closeTo(0.625, 1e-9));
    expect(r.containsKey(PokeType.ice), isFalse);
  });

  test('Calcination + Rapace : efficaces sur 5 types, en difficulté sur Roche',
      () {
    final o = OffenseProfile(const <Move>[_incinerate, _braveBird]);
    expect(
      o.effectiveAgainst.toSet(),
      <PokeType>{
        PokeType.grass,
        PokeType.ice,
        PokeType.bug,
        PokeType.steel,
        PokeType.fighting,
      },
    );
    expect(o.strugglesAgainst, <PokeType>[PokeType.rock]);
  });

  test('bilan : faiblesses partagées et types non couverts', () {
    final summary = TeamSummary(
      defenses: <DefenseProfile>[
        talonflame,
        DefenseProfile(<PokeType>[PokeType.fire]),
        DefenseProfile(<PokeType>[PokeType.water]),
      ],
      offenses: <OffenseProfile>[
        OffenseProfile(const <Move>[_incinerate, _braveBird]),
      ],
    );
    expect(summary.sharedWeaknesses, contains(PokeType.rock));
    expect(summary.sharedWeaknesses, contains(PokeType.water));
    expect(summary.sharedWeaknesses, isNot(contains(PokeType.grass)));
    expect(summary.uncovered, contains(PokeType.water));
    expect(summary.uncovered, isNot(contains(PokeType.grass)));
  });

  test('sans attaque, l\'offensive est neutre partout', () {
    final o = OffenseProfile(const <Move>[]);
    expect(o.effectiveAgainst, isEmpty);
    expect(o.strugglesAgainst, isEmpty);
  });
}
