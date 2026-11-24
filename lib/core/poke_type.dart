/// Les 18 types de Pokémon GO, avec leur nom français.
enum PokeType {
  /// Normal.
  normal('normal', 'Normal'),

  /// Feu.
  fire('fire', 'Feu'),

  /// Eau.
  water('water', 'Eau'),

  /// Plante.
  grass('grass', 'Plante'),

  /// Électrik.
  electric('electric', 'Électrik'),

  /// Glace.
  ice('ice', 'Glace'),

  /// Combat.
  fighting('fighting', 'Combat'),

  /// Poison.
  poison('poison', 'Poison'),

  /// Sol.
  ground('ground', 'Sol'),

  /// Vol.
  flying('flying', 'Vol'),

  /// Psy.
  psychic('psychic', 'Psy'),

  /// Insecte.
  bug('bug', 'Insecte'),

  /// Roche.
  rock('rock', 'Roche'),

  /// Spectre.
  ghost('ghost', 'Spectre'),

  /// Dragon.
  dragon('dragon', 'Dragon'),

  /// Ténèbres.
  dark('dark', 'Ténèbres'),

  /// Acier.
  steel('steel', 'Acier'),

  /// Fée.
  fairy('fairy', 'Fée');

  const PokeType(this.id, this.nameFr);

  /// Identifiant anglais des données (PvPoke).
  final String id;

  /// Nom français affiché.
  final String nameFr;

  /// Type d'identifiant [id], ou `null` s'il est inconnu.
  static PokeType? fromId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Multiplicateur d'une attaque super efficace dans Pokémon GO.
const double superEffective = 1.6;

/// Multiplicateur d'une attaque peu efficace.
const double notVeryEffective = 0.625;

/// Multiplicateur d'une immunité des jeux principaux (double résistance).
const double immune = 0.390625;

const Map<PokeType, Set<PokeType>> _strong = <PokeType, Set<PokeType>>{
  PokeType.normal: <PokeType>{},
  PokeType.fire: {PokeType.grass, PokeType.ice, PokeType.bug, PokeType.steel},
  PokeType.water: {PokeType.fire, PokeType.ground, PokeType.rock},
  PokeType.electric: {PokeType.water, PokeType.flying},
  PokeType.grass: {PokeType.water, PokeType.ground, PokeType.rock},
  PokeType.ice: {
    PokeType.grass,
    PokeType.ground,
    PokeType.flying,
    PokeType.dragon,
  },
  PokeType.fighting: {
    PokeType.normal,
    PokeType.ice,
    PokeType.rock,
    PokeType.dark,
    PokeType.steel,
  },
  PokeType.poison: {PokeType.grass, PokeType.fairy},
  PokeType.ground: {
    PokeType.fire,
    PokeType.electric,
    PokeType.poison,
    PokeType.rock,
    PokeType.steel,
  },
  PokeType.flying: {PokeType.grass, PokeType.fighting, PokeType.bug},
  PokeType.psychic: {PokeType.fighting, PokeType.poison},
  PokeType.bug: {PokeType.grass, PokeType.psychic, PokeType.dark},
  PokeType.rock: {PokeType.fire, PokeType.ice, PokeType.flying, PokeType.bug},
  PokeType.ghost: {PokeType.psychic, PokeType.ghost},
  PokeType.dragon: {PokeType.dragon},
  PokeType.dark: {PokeType.psychic, PokeType.ghost},
  PokeType.steel: {PokeType.ice, PokeType.rock, PokeType.fairy},
  PokeType.fairy: {PokeType.fighting, PokeType.dragon, PokeType.dark},
};

const Map<PokeType, Set<PokeType>> _weak = <PokeType, Set<PokeType>>{
  PokeType.normal: {PokeType.rock, PokeType.steel},
  PokeType.fire: {
    PokeType.fire,
    PokeType.water,
    PokeType.rock,
    PokeType.dragon,
  },
  PokeType.water: {PokeType.water, PokeType.grass, PokeType.dragon},
  PokeType.electric: {PokeType.electric, PokeType.grass, PokeType.dragon},
  PokeType.grass: {
    PokeType.fire,
    PokeType.grass,
    PokeType.poison,
    PokeType.flying,
    PokeType.bug,
    PokeType.dragon,
    PokeType.steel,
  },
  PokeType.ice: {PokeType.fire, PokeType.water, PokeType.ice, PokeType.steel},
  PokeType.fighting: {
    PokeType.poison,
    PokeType.flying,
    PokeType.psychic,
    PokeType.bug,
    PokeType.fairy,
  },
  PokeType.poison: {
    PokeType.poison,
    PokeType.ground,
    PokeType.rock,
    PokeType.ghost,
  },
  PokeType.ground: {PokeType.grass, PokeType.bug},
  PokeType.flying: {PokeType.electric, PokeType.rock, PokeType.steel},
  PokeType.psychic: {PokeType.psychic, PokeType.steel},
  PokeType.bug: {
    PokeType.fire,
    PokeType.fighting,
    PokeType.poison,
    PokeType.flying,
    PokeType.ghost,
    PokeType.steel,
    PokeType.fairy,
  },
  PokeType.rock: {PokeType.fighting, PokeType.ground, PokeType.steel},
  PokeType.ghost: {PokeType.dark},
  PokeType.dragon: {PokeType.steel},
  PokeType.dark: {PokeType.fighting, PokeType.dark, PokeType.fairy},
  PokeType.steel: {
    PokeType.fire,
    PokeType.water,
    PokeType.electric,
    PokeType.steel,
  },
  PokeType.fairy: {PokeType.fire, PokeType.poison, PokeType.steel},
};

const Map<PokeType, Set<PokeType>> _immune = <PokeType, Set<PokeType>>{
  PokeType.normal: {PokeType.ghost},
  PokeType.electric: {PokeType.ground},
  PokeType.fighting: {PokeType.ghost},
  PokeType.poison: {PokeType.steel},
  PokeType.ground: {PokeType.flying},
  PokeType.psychic: {PokeType.dark},
  PokeType.ghost: {PokeType.normal},
  PokeType.dragon: {PokeType.fairy},
};

/// Multiplicateur d'une attaque de type [attack] sur un seul type [defender].
double singleEffectiveness(PokeType attack, PokeType defender) {
  if (_immune[attack]?.contains(defender) ?? false) return immune;
  if (_strong[attack]!.contains(defender)) return superEffective;
  if (_weak[attack]!.contains(defender)) return notVeryEffective;
  return 1;
}

/// Multiplicateur d'une attaque de type [attack] sur un Pokémon de types
/// [defenders] (un ou deux types ; les multiplicateurs se cumulent).
double effectiveness(PokeType attack, List<PokeType> defenders) {
  var m = 1.0;
  for (final d in defenders) {
    m *= singleEffectiveness(attack, d);
  }
  return m;
}

/// Types que [attack] touche en super efficace.
List<PokeType> strongAgainst(PokeType attack) => <PokeType>[
      for (final d in PokeType.values)
        if (singleEffectiveness(attack, d) > 1) d,
    ];

/// Types sur lesquels [attack] est peu efficace (immunités comprises).
List<PokeType> weakAgainst(PokeType attack) => <PokeType>[
      for (final d in PokeType.values)
        if (singleEffectiveness(attack, d) < 1) d,
    ];

/// Types qui touchent [defender] en super efficace.
List<PokeType> weakTo(PokeType defender) => <PokeType>[
      for (final a in PokeType.values)
        if (singleEffectiveness(a, defender) > 1) a,
    ];

/// Types auxquels [defender] résiste (immunités comprises).
List<PokeType> resists(PokeType defender) => <PokeType>[
      for (final a in PokeType.values)
        if (singleEffectiveness(a, defender) < 1) a,
    ];
