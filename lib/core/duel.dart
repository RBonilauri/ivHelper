import 'dart:math' as math;

import 'cp_multiplier.dart';
import 'league.dart';
import 'meta.dart';
import 'moves.dart';
import 'poke_type.dart';
import 'species_repository.dart';
import 'stats.dart';

/// Bonus de dégâts des combats de dresseurs (valeur du jeu, reprise de
/// PvPoke).
const double pvpDamageBonus = 1.2999999523162842;

/// Bonus d'une attaque du même type que le Pokémon.
const double _stab = 1.2;

/// Attaque et défense d'un Pokémon obscur (valeurs du jeu).
const double _shadowAtk = 1.2;
const double _shadowDef = 0.83333331;

/// Énergie maximale.
const int _maxEnergy = 100;

/// Au-delà, le duel est déclaré nul (aucun ne met l'autre K.O.).
const int _maxTurns = 1000;

/// Pokémon prêt pour un duel : stats au niveau donné, une attaque immédiate
/// et ses attaques chargées.
class Fighter {
  /// Crée un combattant à partir de stats déjà calculées.
  const Fighter({
    required this.types,
    required this.atk,
    required this.def,
    required this.hp,
    required this.fast,
    required this.charged,
  });

  /// Types du Pokémon (bonus de même type, efficacité subie).
  final List<PokeType> types;

  /// Attaque effective (multiplicateur de PC et obscur compris).
  final double atk;

  /// Défense effective.
  final double def;

  /// Points de vie.
  final int hp;

  /// Attaque immédiate (avec énergie rapportée et durée en tours).
  final Move fast;

  /// Attaques chargées (avec leur coût en énergie).
  final List<Move> charged;

  /// Combattant de [base] avec ces [iv] au [level] (obscur si [shadow]), ou
  /// `null` si l'immédiate n'a pas d'énergie connue ou s'il n'y a aucune
  /// chargée au coût connu.
  static Fighter? of({
    required BaseStats base,
    required Iv iv,
    required double level,
    required List<PokeType> types,
    required Move? fast,
    required List<Move> charged,
    bool shadow = false,
  }) {
    if (fast == null || fast.energyGain <= 0 || fast.turns <= 0) return null;
    final usable = <Move>[
      for (final c in charged)
        if (c.energy > 0) c,
    ];
    if (usable.isEmpty) return null;
    final m = cpm(level);
    return Fighter(
      types: types,
      atk: (base.atk + iv.atk) * m * (shadow ? _shadowAtk : 1),
      def: (base.def + iv.def) * m * (shadow ? _shadowDef : 1),
      hp: computeHp(base, iv, level),
      fast: fast,
      charged: usable,
    );
  }
}

/// Dégâts de [move] lancée par [attacker] sur [defender], comme le jeu :
/// ⌊puissance × même type × attaque/défense × efficacité × 0,5 × bonus⌋ + 1.
int pvpDamage(Move move, Fighter attacker, Fighter defender) {
  final stab = attacker.types.contains(move.type) ? _stab : 1.0;
  return (move.power *
              stab *
              (attacker.atk / defender.def) *
              effectiveness(move.type, defender.types) *
              0.5 *
              pvpDamageBonus)
          .floor() +
      1;
}

/// Issue d'un duel, vue du premier Pokémon.
enum DuelOutcome {
  /// Il met l'autre K.O. le premier.
  win,

  /// Il est mis K.O. le premier.
  loss,

  /// K.O. en même temps, ou aucun K.O.
  draw,
}

class _Charged {
  const _Charged(this.cost, this.damage);

  final int cost;
  final int damage;
}

class _Side {
  _Side(this.fighter, this.shields) : hp = fighter.hp;

  final Fighter fighter;
  int hp;
  int shields;
  int energy = 0;

  /// Tours restants de l'immédiate en cours (0 : libre).
  int cooldown = 0;
}

/// Attaque chargée lancée maintenant par [side], ou `null` pour attendre.
///
/// L'adversaire a un bouclier : la moins chère, pour le lui faire utiliser.
/// Sinon : celle qui le met K.O. tout de suite si possible, sinon la plus
/// rentable (dégâts par énergie), dès qu'elle est chargée.
_Charged? _choose(_Side side, List<_Charged> moves, _Side target) {
  final ready = <_Charged>[
    for (final c in moves)
      if (side.energy >= c.cost) c,
  ];
  if (ready.isEmpty) return null;
  int cheaper(_Charged a, _Charged b) => a.cost != b.cost
      ? a.cost.compareTo(b.cost)
      : b.damage.compareTo(a.damage);
  if (target.shields > 0) return (ready..sort(cheaper)).first;
  final finishing = <_Charged>[
    for (final c in ready)
      if (c.damage >= target.hp) c,
  ];
  if (finishing.isNotEmpty) return (finishing..sort(cheaper)).first;
  final preferred = (List<_Charged>.of(moves)
        ..sort((a, b) {
          final byRate = (b.damage / b.cost).compareTo(a.damage / a.cost);
          return byRate != 0 ? byRate : a.cost.compareTo(b.cost);
        }))
      .first;
  return side.energy >= preferred.cost ? preferred : null;
}

/// Lance [move] de [side] sur [target] : un bouclier l'arrête (1 dégât).
void _fire(_Side side, _Charged move, _Side target) {
  side.energy -= move.cost;
  if (target.shields > 0) {
    target.shields--;
    target.hp -= 1;
  } else {
    target.hp -= move.damage;
  }
}

DuelOutcome? _ended(_Side a, _Side b) {
  if (a.hp <= 0 && b.hp <= 0) return DuelOutcome.draw;
  if (b.hp <= 0) return DuelOutcome.win;
  if (a.hp <= 0) return DuelOutcome.loss;
  return null;
}

/// Duel estimé de [a] contre [b], chacun avec [shields] boucliers, tour par
/// tour (0,5 s) : attaques immédiates (dégâts et énergie), attaques chargées
/// dès que la stratégie le permet, boucliers toujours utilisés. Deux
/// chargées lancées au même tour : la plus forte attaque passe d'abord.
/// Les changements de stats des attaques ne sont pas pris en compte.
DuelOutcome duel(Fighter a, Fighter b, {int shields = 1}) {
  final sa = _Side(a, shields);
  final sb = _Side(b, shields);
  final fastA = pvpDamage(a.fast, a, b);
  final fastB = pvpDamage(b.fast, b, a);
  final chargedA = <_Charged>[
    for (final c in a.charged) _Charged(c.energy, pvpDamage(c, a, b)),
  ];
  final chargedB = <_Charged>[
    for (final c in b.charged) _Charged(c.energy, pvpDamage(c, b, a)),
  ];
  for (var turn = 0; turn < _maxTurns; turn++) {
    // Attaques chargées, seulement entre deux immédiates.
    final useA = sa.cooldown == 0 ? _choose(sa, chargedA, sb) : null;
    final useB = sb.cooldown == 0 ? _choose(sb, chargedB, sa) : null;
    if (useA != null && useB != null && a.atk == b.atk) {
      _fire(sa, useA, sb);
      _fire(sb, useB, sa);
    } else if (useA != null && (useB == null || a.atk > b.atk)) {
      _fire(sa, useA, sb);
      if (useB != null && sb.hp > 0) _fire(sb, useB, sa);
    } else if (useB != null) {
      _fire(sb, useB, sa);
      if (useA != null && sa.hp > 0) _fire(sa, useA, sb);
    }
    final ended = _ended(sa, sb);
    if (ended != null) return ended;

    // Attaques immédiates : dégâts et énergie à la fin de leur durée.
    var damageToB = 0;
    var damageToA = 0;
    if (useA == null) {
      if (sa.cooldown == 0) sa.cooldown = a.fast.turns;
      if (--sa.cooldown == 0) {
        damageToB = fastA;
        sa.energy = math.min(_maxEnergy, sa.energy + a.fast.energyGain);
      }
    }
    if (useB == null) {
      if (sb.cooldown == 0) sb.cooldown = b.fast.turns;
      if (--sb.cooldown == 0) {
        damageToA = fastB;
        sb.energy = math.min(_maxEnergy, sb.energy + b.fast.energyGain);
      }
    }
    sb.hp -= damageToB;
    sa.hp -= damageToA;
    final after = _ended(sa, sb);
    if (after != null) return after;
  }
  return DuelOutcome.draw;
}

/// Vrai si [a] gagne au moins deux des trois duels contre [b] (0, 1 et 2
/// boucliers chacun).
bool beats(Fighter a, Fighter b) {
  var wins = 0;
  for (final shields in const <int>[0, 1, 2]) {
    if (duel(a, b, shields: shields) == DuelOutcome.win) wins++;
  }
  return wins >= 2;
}

/// IV et niveau du rang 1 par espèce et plafond (calcul coûteux, gardé).
final Map<String, (Iv, double)> _bestIvCache = <String, (Iv, double)>{};

/// Rang 1 d'IV de [base] sous [cpCap], niveau 50 au plus, comme
/// `buildRankTable` (produit de stats, puis PC, puis IV), avec une recherche
/// du niveau par dichotomie.
(Iv, double) _bestIv(BaseStats base, int cpCap) {
  final key = '${base.atk}/${base.def}/${base.sta}/$cpCap';
  final cached = _bestIvCache[key];
  if (cached != null) return cached;
  const top = 98; // niveau 50 : (50 − 1) × 2
  Iv? bestIv;
  var bestLevel = 1.0;
  var bestProduct = -1.0;
  var bestCp = -1;
  for (var atk = 0; atk <= 15; atk++) {
    for (var def = 0; def <= 15; def++) {
      for (var sta = 0; sta <= 15; sta++) {
        final iv = Iv(atk, def, sta);
        var lo = 0;
        var hi = top;
        var found = 0;
        while (lo <= hi) {
          final mid = (lo + hi) >> 1;
          if (computeCp(base, iv, 1 + mid / 2) <= cpCap) {
            found = mid;
            lo = mid + 1;
          } else {
            hi = mid - 1;
          }
        }
        final level = 1 + found / 2;
        final product = statProduct(base, iv, level);
        final cp = computeCp(base, iv, level);
        if (bestIv == null ||
            _better(product, cp, iv, bestProduct, bestCp, bestIv)) {
          bestIv = iv;
          bestLevel = level;
          bestProduct = product;
          bestCp = cp;
        }
      }
    }
  }
  return _bestIvCache[key] = (bestIv!, bestLevel);
}

bool _better(
  double product,
  int cp,
  Iv iv,
  double bestProduct,
  int bestCp,
  Iv best,
) {
  if (product != bestProduct) return product > bestProduct;
  if (cp != bestCp) return cp > bestCp;
  final sum = iv.atk + iv.def + iv.sta;
  final bestSum = best.atk + best.def + best.sta;
  if (sum != bestSum) return sum > bestSum;
  if (iv.atk != best.atk) return iv.atk > best.atk;
  if (iv.def != best.def) return iv.def > best.def;
  return iv.sta > best.sta;
}

/// Adversaire de la méta prêt pour un duel : le rang 1 d'IV de la ligue
/// (niveau 50 au plus) avec les attaques conseillées par PvPoke ; `null` si
/// l'espèce ou une attaque est inconnue.
Fighter? metaFighter(
  MetaEntry entry,
  League league,
  SpeciesRepository repository,
  MoveBook moves,
) {
  final name = entry.species;
  final species = name == null ? null : repository.findByName(name);
  final fast = moves[entry.fast.id];
  final charged = <Move>[
    for (final c in entry.charged)
      if (moves[c.id] case final move?) move,
  ];
  if (species == null ||
      fast == null ||
      charged.length != entry.charged.length) {
    return null;
  }
  final (iv, level) = _bestIv(species.base, league.cpCap);
  return Fighter.of(
    base: species.base,
    iv: iv,
    level: level,
    types: species.types,
    fast: fast,
    charged: charged,
    shadow: entry.shadow,
  );
}
