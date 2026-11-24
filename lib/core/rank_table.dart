import 'stats.dart';

/// Une combinaison d'IV classée dans une ligue.
class RankEntry {
  /// Crée une entrée de classement.
  const RankEntry({
    required this.rank,
    required this.level,
    required this.cp,
    required this.iv,
    required this.statProduct,
    required this.percent,
  });

  /// Rang de 1 à 4096 (1 = meilleur produit de stats).
  final int rank;

  /// Plus haut niveau dont le PC reste sous le plafond de la ligue.
  final double level;

  /// PC à ce niveau.
  final int cp;

  /// Combinaison d'IV.
  final Iv iv;

  /// Produit attaque × défense × PV à ce niveau.
  final double statProduct;

  /// Produit de stats en pourcentage du meilleur produit (rang 1 = 100).
  final double percent;
}

/// Classement des 4096 combinaisons d'IV d'une espèce pour une ligue.
class RankTable {
  /// Crée une table à partir d'entrées déjà triées par rang.
  RankTable(this.entries) : _byIv = {for (final e in entries) e.iv: e};

  /// Entrées triées du rang 1 au rang 4096.
  final List<RankEntry> entries;

  final Map<Iv, RankEntry> _byIv;

  /// Entrée de la combinaison [iv].
  ///
  /// Lève une [ArgumentError] si [iv] n'est pas dans la table.
  RankEntry entryFor(Iv iv) {
    final entry = _byIv[iv];
    if (entry == null) {
      throw ArgumentError.value(iv, 'iv', 'absent de la table');
    }
    return entry;
  }
}

/// Construit le classement de [base] pour un plafond de PC [cpCap].
///
/// Chaque combinaison d'IV prend le plus haut niveau (jusqu'à [maxLevel], par
/// demi-pas) dont le PC ne dépasse pas [cpCap]. Le tri se fait par produit de
/// stats décroissant, puis PC décroissant, puis IV décroissants, de façon
/// déterministe.
RankTable buildRankTable(
  BaseStats base, {
  required int cpCap,
  double maxLevel = 51,
}) {
  final topIndex = ((maxLevel - 1) * 2).round();
  final raw = <_Raw>[];
  for (var atk = 0; atk <= 15; atk++) {
    for (var def = 0; def <= 15; def++) {
      for (var sta = 0; sta <= 15; sta++) {
        final iv = Iv(atk, def, sta);
        var level = 1.0;
        for (var i = topIndex; i >= 0; i--) {
          final candidate = 1 + i / 2;
          if (computeCp(base, iv, candidate) <= cpCap) {
            level = candidate;
            break;
          }
        }
        raw.add(
          _Raw(
            iv: iv,
            level: level,
            cp: computeCp(base, iv, level),
            product: statProduct(base, iv, level),
          ),
        );
      }
    }
  }
  raw.sort(_compare);
  final best = raw.first.product;
  final entries = <RankEntry>[
    for (var i = 0; i < raw.length; i++)
      RankEntry(
        rank: i + 1,
        level: raw[i].level,
        cp: raw[i].cp,
        iv: raw[i].iv,
        statProduct: raw[i].product,
        percent: raw[i].product / best * 100,
      ),
  ];
  return RankTable(entries);
}

class _Raw {
  const _Raw({
    required this.iv,
    required this.level,
    required this.cp,
    required this.product,
  });

  final Iv iv;
  final double level;
  final int cp;
  final double product;
}

int _compare(_Raw a, _Raw b) {
  final byProduct = b.product.compareTo(a.product);
  if (byProduct != 0) return byProduct;
  final byCp = b.cp.compareTo(a.cp);
  if (byCp != 0) return byCp;
  final bySum =
      (b.iv.atk + b.iv.def + b.iv.sta).compareTo(a.iv.atk + a.iv.def + a.iv.sta);
  if (bySum != 0) return bySum;
  final byAtk = b.iv.atk.compareTo(a.iv.atk);
  if (byAtk != 0) return byAtk;
  final byDef = b.iv.def.compareTo(a.iv.def);
  if (byDef != 0) return byDef;
  return b.iv.sta.compareTo(a.iv.sta);
}
