import 'dart:convert';

import 'league.dart';
import 'poke_type.dart';
import 'species_repository.dart';

/// Ligue couverte par la méta.
enum MetaLeague {
  /// Ligue super.
  great('great', 'Super', '1500'),

  /// Ligue hyper.
  ultra('ultra', 'Hyper', '2500'),

  /// Ligue master.
  master('master', 'Master', 'sans limite');

  const MetaLeague(this.key, this.label, this.cap);

  /// Ligue méta de clé [key] (`great`, `ultra`, `master`), `null` pour la
  /// ligue mini, qui n'a pas de méta.
  static MetaLeague? fromKey(String key) {
    for (final l in values) {
      if (l.key == key) return l;
    }
    return null;
  }

  /// Clé dans `meta.json`.
  final String key;

  /// Nom affiché.
  final String label;

  /// Plafond affiché.
  final String cap;
}

/// Une attaque du jeu d'attaques recommandé.
class MetaMove {
  /// Crée une attaque.
  const MetaMove({
    required this.id,
    required this.nameFr,
    required this.type,
    this.power = 0,
    this.elite = false,
  });

  /// Identifiant des données (par exemple `INCINERATE`).
  final String id;

  /// Nom français.
  final String nameFr;

  /// Type de l'attaque.
  final PokeType type;

  /// Puissance en combat de dresseurs (PvP).
  final int power;

  /// Vrai pour une attaque d'événement (Élite).
  final bool elite;

  /// Nom suivi d'un astérisque pour une attaque d'événement.
  String get label => elite ? '$nameFr*' : nameFr;
}

/// Un Pokémon du classement de la méta.
class MetaEntry {
  /// Crée une entrée.
  const MetaEntry({
    required this.rank,
    required this.name,
    required this.species,
    required this.shadow,
    required this.types,
    required this.score,
    required this.fast,
    required this.charged,
    required this.bestMatchups,
    required this.worstMatchups,
  });

  /// Rang dans la ligue (1 = meilleur).
  final int rank;

  /// Nom affiché, avec « (Obscur) » pour une forme obscure.
  final String name;

  /// Nom de l'espèce dans `species.json` (mêmes stats), ou `null`.
  final String? species;

  /// Vrai pour une forme obscure.
  final bool shadow;

  /// Un ou deux types.
  final List<PokeType> types;

  /// Note PvPoke sur 100, ou `null`.
  final double? score;

  /// Attaque immédiate recommandée.
  final MetaMove fast;

  /// Attaques chargées recommandées (une ou deux).
  final List<MetaMove> charged;

  /// Adversaires contre lesquels il s'en sort le mieux.
  final List<String> bestMatchups;

  /// Adversaires qui le mettent le plus en difficulté.
  final List<String> worstMatchups;
}

/// Squelette.
class MetaBoard {
  /// Squelette.
  const MetaBoard({
    required this.key,
    required this.label,
    required this.capLabel,
    required this.league,
    required this.entries,
    this.eligible,
  });

  /// Squelette.
  final String key;

  /// Squelette.
  final String label;

  /// Squelette.
  final String capLabel;

  /// Squelette.
  final League league;

  /// Squelette.
  final List<MetaEntry> entries;

  /// Squelette.
  final Set<String>? eligible;

  /// Squelette.
  bool get isCup => false;

  /// Squelette.
  bool allows(String speciesName, {bool shadow = false}) => false;

  /// Squelette.
  MetaEntry? entryFor(String speciesName, {bool shadow = false}) => null;
}

/// Squelette.
class CupStanding {
  /// Squelette.
  const CupStanding(this.cup, this.entry);

  /// Squelette.
  final MetaBoard cup;

  /// Squelette.
  final MetaEntry? entry;
}

/// Squelette.
List<CupStanding> cupStandings(
  MetaSnapshot meta,
  String speciesName, {
  League? league,
  bool shadow = false,
}) =>
    const <CupStanding>[];

/// Squelette.
String cupStandingLabel(CupStanding standing) => '';

/// La méta d'une date donnée, par ligue.
class MetaSnapshot {
  /// Crée une méta.
  const MetaSnapshot({
    required this.updated,
    required this.leagues,
    this.cups = const <MetaBoard>[],
  });

  /// Squelette.
  final List<MetaBoard> cups;

  /// Squelette.
  List<MetaBoard> get boards => const <MetaBoard>[];

  /// Squelette.
  MetaBoard boardOf(MetaLeague league) => MetaBoard(
        key: league.key,
        label: league.label,
        capLabel: league.cap,
        league: League.great,
        entries: leagues[league] ?? const <MetaEntry>[],
      );

  /// Squelette.
  MetaBoard? boardByKey(String key) => null;

  /// Lit `meta.json` produit par `tool/build_meta.py`.
  ///
  /// Lève une [FormatException] si le contenu est illisible.
  factory MetaSnapshot.fromJson(String source) {
    try {
      final root = jsonDecode(source) as Map<String, dynamic>;
      final leaguesRaw = root['leagues'] as Map<String, dynamic>;
      return MetaSnapshot(
        updated: root['updated'] as String,
        leagues: <MetaLeague, List<MetaEntry>>{
          for (final league in MetaLeague.values)
            league: <MetaEntry>[
              for (final raw in (leaguesRaw[league.key] as List<dynamic>?) ??
                  const <dynamic>[])
                _entry(raw as Map<String, dynamic>),
            ],
        },
      );
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('méta illisible : $e');
    }
  }

  /// Date de mise à jour au format ISO (`2026-11-24`).
  final String updated;

  /// Classement de chaque ligue.
  final Map<MetaLeague, List<MetaEntry>> leagues;

  /// Date de mise à jour au format français (`24/11/2026`).
  String get updatedFr {
    final parts = updated.split('-');
    if (parts.length != 3) return updated;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  /// Attaques recommandées (immédiate puis chargées) pour l'espèce
  /// [speciesName] dans la ligue de clé [leagueKey] (`great`, `ultra`,
  /// `master`) : la forme obscure si [shadow], sinon la forme normale, à
  /// défaut l'autre. Vide si l'espèce n'est pas dans le classement.
  List<String> movesetFor(
    String speciesName,
    String leagueKey, {
    bool shadow = false,
  }) {
    final league = MetaLeague.fromKey(leagueKey);
    final pick =
        league == null ? null : entryFor(speciesName, league, shadow: shadow);
    if (pick == null) return const <String>[];
    return <String>[pick.fast.id, for (final c in pick.charged) c.id];
  }

  /// Entrée de [speciesName] dans [league] : la forme obscure si [shadow] et
  /// qu'elle est classée, sinon la première forme classée ; `null` si
  /// l'espèce n'est pas dans cette méta.
  MetaEntry? entryFor(
    String speciesName,
    MetaLeague league, {
    bool shadow = false,
  }) {
    final matches = <MetaEntry>[
      for (final e in leagues[league] ?? const <MetaEntry>[])
        if (e.species == speciesName) e,
    ];
    if (matches.isEmpty) return null;
    return matches.firstWhere(
      (e) => e.shadow == shadow,
      orElse: () => matches.first,
    );
  }

  /// Comme [movesetFor] dans la ligue [leagueKey] ; si l'espèce n'y est pas
  /// classée (ou en ligue mini, sans méta), prend la première ligue où elle
  /// l'est : super, puis hyper, puis master.
  List<String> movesetForAnyLeague(
    String speciesName,
    String leagueKey, {
    bool shadow = false,
  }) {
    for (final key in <String>[leagueKey, 'great', 'ultra', 'master']) {
      final moves = movesetFor(speciesName, key, shadow: shadow);
      if (moves.isNotEmpty) return moves;
    }
    return const <String>[];
  }

  /// Vrai si cette méta est plus récente que [other].
  bool isNewerThan(MetaSnapshot other) => updated.compareTo(other.updated) > 0;
}

MetaEntry _entry(Map<String, dynamic> raw) => MetaEntry(
      rank: raw['rank'] as int,
      name: raw['name'] as String,
      species: raw['species'] as String?,
      shadow: raw['shadow'] as bool? ?? false,
      types: _types(raw['types'] as List<dynamic>),
      score: (raw['score'] as num?)?.toDouble(),
      fast: _move(raw['fast'] as Map<String, dynamic>),
      charged: <MetaMove>[
        for (final m in raw['charged'] as List<dynamic>)
          _move(m as Map<String, dynamic>),
      ],
      bestMatchups: _strings(raw['bestMatchups']),
      worstMatchups: _strings(raw['worstMatchups']),
    );

MetaMove _move(Map<String, dynamic> raw) => MetaMove(
      id: raw['id'] as String,
      nameFr: raw['name'] as String,
      type: PokeType.fromId(raw['type'] as String) ?? PokeType.normal,
      power: (raw['power'] as num?)?.toInt() ?? 0,
      elite: raw['elite'] as bool? ?? false,
    );

List<PokeType> _types(List<dynamic> raw) => <PokeType>[
      for (final id in raw)
        if (PokeType.fromId(id as String) != null) PokeType.fromId(id)!,
    ];

List<String> _strings(Object? raw) => <String>[
      for (final v in (raw as List<dynamic>?) ?? const <dynamic>[]) v as String,
    ];

/// Filtre la liste méta. Les critères se combinent (ET) ; dans [types] et
/// [moveTypes], un seul type choisi suffit (OU). [moveTypes] porte sur les
/// attaques recommandées (immédiate ou chargées) ; [keep] ajoute un critère
/// libre (par exemple : possédé dans cette ligue).
List<MetaEntry> filterMeta(
  Iterable<MetaEntry> entries, {
  String query = '',
  Set<PokeType> types = const <PokeType>{},
  Set<PokeType> moveTypes = const <PokeType>{},
  bool Function(MetaEntry entry)? keep,
}) {
  final q = normalizeName(query);
  return <MetaEntry>[
    for (final e in entries)
      if ((q.isEmpty || normalizeName(e.name).contains(q)) &&
          (types.isEmpty || e.types.any(types.contains)) &&
          (moveTypes.isEmpty ||
              <MetaMove>[e.fast, ...e.charged]
                  .any((m) => moveTypes.contains(m.type))) &&
          (keep == null || keep(e)))
        e,
  ];
}
