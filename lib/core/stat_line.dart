import 'rank_table.dart';
import 'stats.dart';

/// Stats réelles d'une entrée du classement, à son niveau.
class StatLine {
  /// Crée une ligne de stats.
  const StatLine({
    required this.atk,
    required this.def,
    required this.hp,
    required this.product,
  });

  /// Attaque réelle (stat de base plus IV, fois le multiplicateur).
  final double atk;

  /// Défense réelle.
  final double def;

  /// PV réels.
  final int hp;

  /// Produit des stats (stat globale).
  final double product;
}

/// Calcule les stats réelles de [entry] pour l'espèce [base].
StatLine statLine(BaseStats base, RankEntry entry) {
  final m = cpm(entry.level);
  return StatLine(
    atk: (base.atk + entry.iv.atk) * m,
    def: (base.def + entry.iv.def) * m,
    hp: computeHp(base, entry.iv, entry.level),
    product: entry.statProduct,
  );
}
