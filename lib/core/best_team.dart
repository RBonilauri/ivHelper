import 'collection.dart';
import 'duel.dart';
import 'meta.dart';
import 'poke_type.dart';

/// Pokémon de la collection pris en compte pour « Ma meilleure équipe ».
class TeamCandidate {
  /// Crée un candidat.
  const TeamCandidate({
    required this.id,
    required this.species,
    required this.shadow,
    required this.types,
    required this.moveTypes,
    required this.ivRank,
    this.metaName,
    this.metaRank,
    this.metaScore,
    this.beats = const <String>[],
    this.losesTo = const <String>[],
    this.fighter,
  });

  /// Squelette.
  final Fighter? fighter;

  /// Identifiant de l'entrée de collection.
  final String id;

  /// Nom de l'espèce.
  final String species;

  /// Vrai pour un Pokémon obscur.
  final bool shadow;

  /// Types du Pokémon.
  final List<PokeType> types;

  /// Types de ses attaques : enregistrées, sinon conseillées par la méta,
  /// sinon apprenables.
  final List<PokeType> moveTypes;

  /// Rang d'IV dans la ligue (1 = meilleur).
  final int ivRank;

  /// Nom dans la méta (« Tortank (Obscur) »), ou `null` s'il n'est pas classé.
  final String? metaName;

  /// Rang méta dans la ligue, ou `null` s'il n'est pas classé.
  final int? metaRank;

  /// Note PvPoke sur 100, ou `null`.
  final double? metaScore;

  /// Adversaires que PvPoke lui fait battre.
  final List<String> beats;

  /// Adversaires que PvPoke lui fait perdre.
  final List<String> losesTo;
}

/// Équipe de trois proposée et ce qu'elle couvre du haut de la méta.
class TeamProposal {
  /// Crée une proposition.
  const TeamProposal({
    required this.members,
    required this.coverage,
    required this.covered,
    required this.total,
    required this.threats,
  });

  /// Les trois membres, dans l'ordre de la collection.
  final List<TeamCandidate> members;

  /// Part pondérée des adversaires couverts, de 0 à 1 (le haut de la méta
  /// compte davantage).
  final double coverage;

  /// Nombre d'adversaires qu'au moins un membre contre.
  final int covered;

  /// Nombre d'adversaires examinés.
  final int total;

  /// Adversaires qu'aucun membre ne contre, du mieux classé au moins bien.
  final List<String> threats;
}

/// Multiplicateur « super efficace » de Pokémon GO.
const double _superEffective = 1.6;

/// Vrai si [c] contre l'adversaire [o].
///
/// Les matchs PvPoke décident d'abord (ceux du candidat, puis ceux de
/// l'adversaire) ; à défaut, il faut une attaque super efficace sur
/// l'adversaire sans subir d'attaque super efficace de sa part.
bool counters(TeamCandidate c, MetaEntry o, {Fighter? opponent}) {
  if (c.beats.contains(o.name)) return true;
  if (c.losesTo.contains(o.name)) return false;
  final name = c.metaName;
  if (name != null) {
    if (o.worstMatchups.contains(name)) return true;
    if (o.bestMatchups.contains(name)) return false;
  }
  final hits = c.moveTypes.any(
    (t) => effectiveness(t, o.types) >= _superEffective,
  );
  if (!hits) return false;
  final threats = <PokeType>[o.fast.type, for (final m in o.charged) m.type];
  return !threats.any((t) => effectiveness(t, c.types) >= _superEffective);
}

/// Nombre maximal de candidats examinés (les mieux couvrants).
const int _poolSize = 40;

/// Les [count] meilleures équipes de trois espèces distinctes parmi
/// [candidates], contre les [top] premiers de [opponents].
///
/// L'adversaire de rang i (à partir de 0) sur N pèse `2 − i/N`. Les équipes
/// sont classées par couverture, puis par somme des notes méta, puis par
/// somme des rangs d'IV. Pour une même espèce (et même état obscur), seul
/// le meilleur rang d'IV est gardé. Liste vide s'il y a moins de trois
/// espèces.
List<TeamProposal> bestTeams(
  List<TeamCandidate> candidates,
  List<MetaEntry> opponents, {
  int top = 50,
  int count = 3,
  List<Fighter?>? opponentFighters,
}) {
  final foes = opponents.take(top).toList();
  final n = foes.length;
  final weights = <double>[for (var i = 0; i < n; i++) 2 - i / n];
  final totalWeight = weights.fold<double>(0, (a, b) => a + b);

  // Un seul exemplaire par espèce et état obscur : le meilleur rang d'IV.
  final best = <String, TeamCandidate>{};
  final order = <String>[];
  for (final c in candidates) {
    final key = '${c.species}|${c.shadow}';
    final kept = best[key];
    if (kept == null) {
      order.add(key);
      best[key] = c;
    } else if (c.ivRank < kept.ivRank) {
      best[key] = c;
    }
  }
  final unique = <TeamCandidate>[for (final k in order) best[k]!];

  final masks = <List<bool>>[
    for (final c in unique) <bool>[for (final o in foes) counters(c, o)],
  ];
  double weightOf(List<bool> covered) {
    var w = 0.0;
    for (var i = 0; i < n; i++) {
      if (covered[i]) w += weights[i];
    }
    return w;
  }

  // Les mieux couvrants d'abord, pour borner l'énumération.
  final pool = <int>[for (var i = 0; i < unique.length; i++) i]
    ..sort((a, b) {
      final byWeight = weightOf(masks[b]).compareTo(weightOf(masks[a]));
      return byWeight != 0 ? byWeight : a.compareTo(b);
    });
  if (pool.length > _poolSize) pool.removeRange(_poolSize, pool.length);
  pool.sort();

  final scored = <_Scored>[];
  for (var x = 0; x < pool.length; x++) {
    for (var y = x + 1; y < pool.length; y++) {
      if (unique[pool[x]].species == unique[pool[y]].species) continue;
      for (var z = y + 1; z < pool.length; z++) {
        final idx = <int>[pool[x], pool[y], pool[z]];
        final team = <TeamCandidate>[for (final i in idx) unique[i]];
        if (team[2].species == team[0].species ||
            team[2].species == team[1].species) {
          continue;
        }
        final covered = <bool>[
          for (var i = 0; i < n; i++)
            masks[idx[0]][i] || masks[idx[1]][i] || masks[idx[2]][i],
        ];
        scored.add(
          _Scored(
            team,
            covered,
            totalWeight == 0 ? 0 : weightOf(covered) / totalWeight,
            team.fold<double>(0, (a, c) => a + (c.metaScore ?? 0)),
            team.fold<int>(0, (a, c) => a + c.ivRank),
          ),
        );
      }
    }
  }
  scored.sort((a, b) {
    final byCoverage = b.coverage.compareTo(a.coverage);
    if (byCoverage != 0) return byCoverage;
    final byScore = b.metaScore.compareTo(a.metaScore);
    if (byScore != 0) return byScore;
    return a.ivRanks.compareTo(b.ivRanks);
  });
  return <TeamProposal>[
    for (final s in scored.take(count))
      TeamProposal(
        members: s.team,
        coverage: s.coverage,
        covered: s.covered.where((c) => c).length,
        total: n,
        threats: <String>[
          for (var i = 0; i < n; i++)
            if (!s.covered[i]) foes[i].name,
        ],
      ),
  ];
}

class _Scored {
  _Scored(this.team, this.covered, this.coverage, this.metaScore, this.ivRanks);

  final List<TeamCandidate> team;
  final List<bool> covered;
  final double coverage;
  final double metaScore;
  final int ivRanks;
}

/// Méta correspondant à [league], ou `null` (pas de méta en ligue Mini).
MetaLeague? metaLeagueOf(League league) => switch (league) {
      League.little => null,
      League.great => MetaLeague.great,
      League.ultra => MetaLeague.ultra,
      League.master => MetaLeague.master,
    };

/// Candidats de [rows] tagués dans [league], complétés par la méta.
///
/// Vide en ligue Mini, faute de méta.
List<TeamCandidate> teamCandidates(
  List<CollectionRow> rows,
  League league,
  MetaSnapshot meta,
) {
  final metaLeague = metaLeagueOf(league);
  if (metaLeague == null) return const <TeamCandidate>[];
  return <TeamCandidate>[
    for (final row in rows)
      if (row.entry.league == league) _candidate(row, metaLeague, meta),
  ];
}

TeamCandidate _candidate(
  CollectionRow row,
  MetaLeague league,
  MetaSnapshot meta,
) {
  final shadow = row.entry.shadow == ShadowState.shadow;
  final entry = meta.entryFor(row.entry.speciesName, league, shadow: shadow);
  final List<PokeType> moveTypes;
  if (row.recordedMoves.isNotEmpty) {
    moveTypes = <PokeType>[for (final m in row.recordedMoves) m.type];
  } else if (entry != null) {
    moveTypes = <PokeType>[
      entry.fast.type,
      for (final m in entry.charged) m.type,
    ];
  } else {
    moveTypes = <PokeType>[for (final m in row.learnableMoves) m.type];
  }
  return TeamCandidate(
    id: row.entry.id,
    species: row.entry.speciesName,
    shadow: shadow,
    types: row.species.types,
    moveTypes: _distinct(moveTypes),
    ivRank: row.entry.rank,
    metaName: entry?.name,
    metaRank: entry?.rank,
    metaScore: entry?.score,
    beats: entry?.bestMatchups ?? const <String>[],
    losesTo: entry?.worstMatchups ?? const <String>[],
  );
}

List<PokeType> _distinct(List<PokeType> types) {
  final seen = <PokeType>{};
  return <PokeType>[
    for (final t in types)
      if (seen.add(t)) t,
  ];
}
