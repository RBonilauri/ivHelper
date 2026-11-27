import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/duel.dart';
import 'package:ivhelper/core/league.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/rank_table.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';

Move _fast(PokeType type, int power, int gain, int turns, {String? id}) =>
    Move(
      id: id ?? 'F_${type.id}_$power',
      nameFr: 'Immédiate',
      type: type,
      isFast: true,
      power: power,
      energyGain: gain,
      turns: turns,
    );

Move _charged(PokeType type, int power, int energy, {String? id}) => Move(
      id: id ?? 'C_${type.id}_$power',
      nameFr: 'Chargée',
      type: type,
      isFast: false,
      power: power,
      energy: energy,
    );

Fighter _fighter(
  PokeType type,
  Move fast,
  List<Move> charged, {
  double atk = 120,
  double def = 120,
  int hp = 150,
}) =>
    Fighter(
      types: <PokeType>[type],
      atk: atk,
      def: def,
      hp: hp,
      fast: fast,
      charged: charged,
    );

void main() {
  test('dégâts PvP : stats, bonus de même type, efficacité', () {
    // ⌊20 × 1,2 (même type) × 120/100 × 1,6 × 0,5 × 1,3⌋ + 1 = 30, vérifié
    // par un calcul indépendant.
    final attacker = _fighter(
      PokeType.fire,
      _fast(PokeType.fire, 20, 20, 5),
      <Move>[_charged(PokeType.fire, 90, 50)],
      atk: 120,
    );
    final defender = _fighter(
      PokeType.grass,
      _fast(PokeType.grass, 5, 5, 1),
      <Move>[_charged(PokeType.grass, 90, 50)],
      def: 100,
    );
    expect(pvpDamage(attacker.fast, attacker, defender), 30);
  });

  test('stats d\'un Pokémon réel, forme obscure comprise', () {
    const base = BaseStats(176, 155, 186);
    final fast = _fast(PokeType.fire, 20, 20, 5);
    final charged = <Move>[_charged(PokeType.flying, 130, 55)];
    final f = Fighter.of(
      base: base,
      iv: const Iv(15, 15, 15),
      level: 50,
      types: const <PokeType>[PokeType.fire, PokeType.flying],
      fast: fast,
      charged: charged,
    )!;
    expect(f.atk, closeTo(160.4973044991492, 1e-9));
    expect(f.def, closeTo(142.85100400447834, 1e-9));
    expect(f.hp, 168);
    final shadow = Fighter.of(
      base: base,
      iv: const Iv(15, 15, 15),
      level: 50,
      types: const <PokeType>[PokeType.fire, PokeType.flying],
      fast: fast,
      charged: charged,
      shadow: true,
    )!;
    expect(shadow.atk, closeTo(192.59676539897904, 1e-6));
    expect(shadow.def, closeTo(119.04250000387519, 1e-6));
    expect(shadow.hp, 168);
    // Sans énergie connue pour l'immédiate, ou sans chargée : pas de duel.
    expect(
      Fighter.of(
        base: base,
        iv: const Iv(15, 15, 15),
        level: 50,
        types: const <PokeType>[PokeType.fire],
        fast: Move(
          id: 'X',
          nameFr: 'X',
          type: PokeType.fire,
          isFast: true,
          power: 10,
        ),
        charged: charged,
      ),
      isNull,
    );
    expect(
      Fighter.of(
        base: base,
        iv: const Iv(15, 15, 15),
        level: 50,
        types: const <PokeType>[PokeType.fire],
        fast: fast,
        charged: const <Move>[],
      ),
      isNull,
    );
  });

  test('miroir : match nul, quels que soient les boucliers', () {
    final f = _fighter(
      PokeType.normal,
      _fast(PokeType.normal, 5, 8, 2),
      <Move>[_charged(PokeType.normal, 70, 40)],
    );
    for (final shields in <int>[0, 1, 2]) {
      expect(duel(f, f, shields: shields), DuelOutcome.draw);
    }
    expect(beats(f, f), isFalse);
  });

  test('une attaque immédiate qui charge plus vite gagne le duel', () {
    final charged = <Move>[_charged(PokeType.normal, 100, 50)];
    final quick = _fighter(
      PokeType.normal,
      _fast(PokeType.normal, 3, 10, 1),
      charged,
    );
    final slow = _fighter(
      PokeType.normal,
      _fast(PokeType.normal, 3, 3, 1),
      charged,
    );
    for (final shields in <int>[0, 1, 2]) {
      expect(duel(quick, slow, shields: shields), DuelOutcome.win);
      expect(duel(slow, quick, shields: shields), DuelOutcome.loss);
    }
    expect(beats(quick, slow), isTrue);
    expect(beats(slow, quick), isFalse);
  });

  test('l\'avantage de type ne suffit pas avec des attaques trop faibles', () {
    final water = _fighter(
      PokeType.water,
      _fast(PokeType.water, 1, 1, 2),
      <Move>[_charged(PokeType.water, 50, 100)],
    );
    final fire = _fighter(
      PokeType.fire,
      _fast(PokeType.fire, 12, 8, 1),
      <Move>[_charged(PokeType.fire, 60, 40)],
    );
    expect(beats(water, fire), isFalse);
    expect(beats(fire, water), isTrue);
  });

  test('adversaire de la méta : rang 1 d\'IV de la ligue, niveau 50 au plus',
      () {
    final species = Species(
      dex: 663,
      nameFr: 'Flambusard',
      base: BaseStats(176, 155, 186),
      types: const <PokeType>[PokeType.fire, PokeType.flying],
    );
    final repo = SpeciesRepository(<Species>[species]);
    final moves = MoveBook(<Move>[
      _fast(PokeType.fire, 20, 20, 5, id: 'INCINERATE'),
      _charged(PokeType.flying, 130, 55, id: 'BRAVE_BIRD'),
    ]);
    MetaEntry entry({String fastId = 'INCINERATE', bool shadow = false}) =>
        MetaEntry(
          rank: 1,
          name: 'Flambusard',
          species: 'Flambusard',
          shadow: shadow,
          types: const <PokeType>[PokeType.fire, PokeType.flying],
          score: 90,
          fast: MetaMove(id: fastId, nameFr: 'Calcination', type: PokeType.fire),
          charged: const <MetaMove>[
            MetaMove(id: 'BRAVE_BIRD', nameFr: 'Rapace', type: PokeType.flying),
          ],
          bestMatchups: const <String>[],
          worstMatchups: const <String>[],
        );
    final f = metaFighter(entry(), League.great, repo, moves)!;
    final best = buildRankTable(species.base, cpCap: 1500, maxLevel: 50)
        .entries
        .first;
    expect(f.hp, computeHp(species.base, best.iv, best.level));
    expect(f.fast.id, 'INCINERATE');
    expect(f.charged.single.id, 'BRAVE_BIRD');
    // Attaque inconnue : pas de duel possible.
    expect(metaFighter(entry(fastId: 'X'), League.great, repo, moves), isNull);
    // Master : 15/15/15 au niveau 50.
    final master = metaFighter(entry(), League.master, repo, moves)!;
    expect(master.hp, computeHp(species.base, const Iv(15, 15, 15), 50));
  });
}
