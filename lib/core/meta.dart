import 'dart:convert';

import 'poke_type.dart';

/// Ligue couverte par la méta.
enum MetaLeague {
  /// Ligue super.
  great('great', 'Super', '1500'),

  /// Ligue hyper.
  ultra('ultra', 'Hyper', '2500'),

  /// Ligue master.
  master('master', 'Master', 'sans limite');

  const MetaLeague(this.key, this.label, this.cap);

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

/// La méta d'une date donnée, par ligue.
class MetaSnapshot {
  /// Crée une méta.
  const MetaSnapshot({required this.updated, required this.leagues});

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
    MetaLeague? league;
    for (final l in MetaLeague.values) {
      if (l.key == leagueKey) league = l;
    }
    if (league == null) return const <String>[];
    final matches = <MetaEntry>[
      for (final e in leagues[league] ?? const <MetaEntry>[])
        if (e.species == speciesName) e,
    ];
    if (matches.isEmpty) return const <String>[];
    final pick = matches.firstWhere(
      (e) => e.shadow == shadow,
      orElse: () => matches.first,
    );
    return <String>[pick.fast.id, for (final c in pick.charged) c.id];
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
