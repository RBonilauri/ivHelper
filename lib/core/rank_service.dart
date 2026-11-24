import 'rank_table.dart';
import 'stats.dart';

/// Plafond de PC de la ligue super.
const int greatCpCap = 1500;

/// Plafond de PC de la ligue hyper.
const int ultraCpCap = 2500;

/// Classement d'une espèce dans une ligue et place de la combinaison saisie.
class LeagueResult {
  /// Crée un résultat de ligue.
  const LeagueResult({
    required this.cpCap,
    required this.table,
    required this.mine,
  });

  /// Plafond de PC de la ligue.
  final int cpCap;

  /// Classement complet des 4096 combinaisons.
  final RankTable table;

  /// Entrée de la combinaison saisie.
  final RankEntry mine;

  /// Les [n] premières entrées du classement.
  List<RankEntry> top(int n) => table.entries.take(n).toList();
}

/// Résultats en ligue super et en ligue hyper.
class RankResult {
  /// Crée un résultat pour les deux ligues.
  const RankResult({required this.great, required this.ultra});

  /// Ligue super (1500 PC).
  final LeagueResult great;

  /// Ligue hyper (2500 PC).
  final LeagueResult ultra;
}

/// Classe la combinaison [iv] de l'espèce [base] en ligue super et hyper.
///
/// [maxLevel] vaut 51 par défaut (niveau 50 plus bonus meilleur ami).
/// [minIv] restreint le classement aux combinaisons dont chaque IV vaut au
/// moins cette valeur ; [iv] doit alors respecter ce plancher.
RankResult rankIv(
  BaseStats base,
  Iv iv, {
  double maxLevel = 51,
  int minIv = 0,
}) {
  LeagueResult league(int cpCap) {
    final table = buildRankTable(
      base,
      cpCap: cpCap,
      maxLevel: maxLevel,
      minIv: minIv,
    );
    return LeagueResult(
      cpCap: cpCap,
      table: table,
      mine: table.entryFor(iv),
    );
  }

  return RankResult(great: league(greatCpCap), ultra: league(ultraCpCap));
}
