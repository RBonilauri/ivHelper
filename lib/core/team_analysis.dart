import 'moves.dart';
import 'poke_type.dart';

/// Un type et son multiplicateur.
class TypeFactor {
  /// Crée un couple type et multiplicateur.
  const TypeFactor(this.type, this.factor);

  /// Type concerné.
  final PokeType type;

  /// Multiplicateur de dégâts.
  final double factor;
}

/// Analyse défensive d'un Pokémon : ce qui le touche fort ou peu.
class DefenseProfile {
  /// Analyse un Pokémon de types [types].
  DefenseProfile(this.types)
      : factors = {
          for (final a in PokeType.values) a: effectiveness(a, types),
        };

  /// Types du Pokémon.
  final List<PokeType> types;

  /// Multiplicateur subi pour chaque type d'attaque.
  final Map<PokeType, double> factors;

  /// Types d'attaque qui lui font plus de dégâts, du plus fort au moins fort.
  List<TypeFactor> get weaknesses => _sorted((f) => f > 1, descending: true);

  /// Types d'attaque auxquels il résiste, de la plus forte résistance à la
  /// moins forte.
  List<TypeFactor> get resistances => _sorted((f) => f < 1, descending: false);

  List<TypeFactor> _sorted(
    bool Function(double) keep, {
    required bool descending,
  }) {
    final list = <TypeFactor>[
      for (final e in factors.entries)
        if (keep(e.value)) TypeFactor(e.key, e.value),
    ];
    list.sort(
      (a, b) => descending
          ? b.factor.compareTo(a.factor)
          : a.factor.compareTo(b.factor),
    );
    return list;
  }
}

/// Analyse offensive d'un jeu d'attaques : meilleur multiplicateur par type
/// défenseur (types simples).
class OffenseProfile {
  /// Analyse les [moves] d'un Pokémon.
  OffenseProfile(this.moves)
      : best = {
          for (final d in PokeType.values)
            d: moves.isEmpty
                ? 1.0
                : moves
                    .map((m) => singleEffectiveness(m.type, d))
                    .reduce((a, b) => a > b ? a : b),
        };

  /// Attaques prises en compte.
  final List<Move> moves;

  /// Meilleur multiplicateur infligé à chaque type défenseur.
  final Map<PokeType, double> best;

  /// Types touchés en super efficace par au moins une attaque.
  List<PokeType> get effectiveAgainst => <PokeType>[
        for (final e in best.entries)
          if (e.value > 1) e.key,
      ];

  /// Types sur lesquels aucune attaque n'est au moins neutre.
  List<PokeType> get strugglesAgainst => <PokeType>[
        for (final e in best.entries)
          if (e.value < 1) e.key,
      ];
}

/// Bilan d'une équipe de Pokémon.
class TeamSummary {
  /// Établit le bilan à partir des profils des membres renseignés.
  TeamSummary({
    required List<DefenseProfile> defenses,
    required List<OffenseProfile> offenses,
  })  : sharedWeaknesses = <PokeType>[
          for (final a in PokeType.values)
            if (defenses.where((d) => d.factors[a]! > 1).length >= 2) a,
        ],
        unresisted = <PokeType>[
          if (defenses.isNotEmpty)
            for (final a in PokeType.values)
              if (defenses.every((d) => d.factors[a]! >= 1)) a,
        ],
        uncovered = <PokeType>[
          if (offenses.isNotEmpty)
            for (final d in PokeType.values)
              if (offenses.every((o) => o.best[d]! <= 1)) d,
        ];

  /// Types d'attaque auxquels au moins deux membres sont faibles.
  final List<PokeType> sharedWeaknesses;

  /// Types d'attaque auxquels aucun membre ne résiste.
  final List<PokeType> unresisted;

  /// Types qu'aucune attaque de l'équipe ne touche en super efficace.
  final List<PokeType> uncovered;
}
