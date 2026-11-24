import 'dart:math' as math;

import 'cp_multiplier.dart';

export 'cp_multiplier.dart' show cpm;

/// Stats de base d'une espèce (attaque, défense, endurance/PV).
class BaseStats {
  /// Crée des stats de base.
  const BaseStats(this.atk, this.def, this.sta);

  /// Attaque de base.
  final int atk;

  /// Défense de base.
  final int def;

  /// Endurance de base (PV).
  final int sta;
}

/// IV d'un Pokémon, chacun de 0 à 15.
class Iv {
  /// Crée une combinaison d'IV.
  const Iv(this.atk, this.def, this.sta);

  /// IV d'attaque.
  final int atk;

  /// IV de défense.
  final int def;

  /// IV de PV.
  final int sta;

  @override
  bool operator ==(Object other) =>
      other is Iv && other.atk == atk && other.def == def && other.sta == sta;

  @override
  int get hashCode => Object.hash(atk, def, sta);

  @override
  String toString() => '$atk/$def/$sta';
}

/// PC d'un Pokémon de [base] avec les [iv] au [level], jamais sous 10.
int computeCp(BaseStats base, Iv iv, double level) {
  final m = cpm(level);
  final cp = ((base.atk + iv.atk) *
          math.sqrt(base.def + iv.def) *
          math.sqrt(base.sta + iv.sta) *
          math.pow(m, 2) /
          10)
      .floor();
  return math.max(cp, 10);
}

/// PV d'un Pokémon de [base] avec les [iv] au [level], jamais sous 10.
int computeHp(BaseStats base, Iv iv, double level) {
  return math.max(((base.sta + iv.sta) * cpm(level)).floor(), 10);
}

/// Produit des stats (attaque × défense × PV) utilisé pour classer les IV.
double statProduct(BaseStats base, Iv iv, double level) {
  final m = cpm(level);
  return (base.atk + iv.atk) *
      m *
      (base.def + iv.def) *
      m *
      computeHp(base, iv, level);
}
