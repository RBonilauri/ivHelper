import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'poke_type.dart';

/// Pokémon dont une attaque change les stats.
enum StatTarget {
  /// Le Pokémon qui lance l'attaque.
  self,

  /// L'adversaire.
  opponent,
}

/// Changement de stats provoqué par une attaque, en crans (−4 à +4).
class StatChange {
  /// Crée un changement.
  const StatChange({
    required this.target,
    this.attack = 0,
    this.defense = 0,
    this.chance = 1,
  });

  /// Pokémon touché.
  final StatTarget target;

  /// Crans d'attaque (négatif : baisse).
  final int attack;

  /// Crans de défense (négatif : baisse).
  final int defense;

  /// Probabilité que l'effet se produise (1 : toujours).
  final double chance;

  /// Vrai si l'effet aide le lanceur : hausse sur soi ou baisse chez
  /// l'adversaire.
  bool get isBeneficial {
    final sum = attack + defense;
    return target == StatTarget.self ? sum > 0 : sum < 0;
  }
}

/// Une attaque de Pokémon GO.
class Move {
  /// Crée une attaque.
  const Move({
    required this.id,
    required this.nameFr,
    required this.type,
    required this.isFast,
    this.power = 0,
    this.energy = 0,
    this.effects = const <StatChange>[],
    this.energyGain = 0,
    this.turns = 1,
  });

  /// Squelette.
  final int energyGain;

  /// Squelette.
  final int turns;

  /// Identifiant des données (par exemple `INCINERATE`).
  final String id;

  /// Nom français.
  final String nameFr;

  /// Type de l'attaque.
  final PokeType type;

  /// Vrai pour une attaque immédiate, faux pour une attaque chargée.
  final bool isFast;

  /// Puissance en combat de dresseurs (PvP).
  final int power;

  /// Énergie coûtée par une attaque chargée (0 si inconnue ou immédiate).
  final int energy;

  /// Changements de stats provoqués (sur soi ou l'adversaire).
  final List<StatChange> effects;

  /// Nombre de barres d'énergie affichées par le jeu : 3 pour une attaque
  /// très courte (≤ 33), 2 jusqu'à 50, 1 au-delà ; 0 pour une immédiate.
  int get chargeBars =>
      isFast || energy <= 0 ? 0 : (100 ~/ energy).clamp(1, 3);
}

/// Toutes les attaques connues, par identifiant.
class MoveBook {
  /// Crée un recueil à partir de [moves].
  MoveBook(Iterable<Move> moves) : _byId = {for (final m in moves) m.id: m};

  /// Lit `assets/moves.json` produit par `tool/build_species.py`.
  factory MoveBook.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final moves = <Move>[];
    for (final entry in map.entries) {
      final raw = entry.value as Map<String, dynamic>;
      final type = PokeType.fromId(raw['type'] as String);
      if (type == null) continue;
      moves.add(
        Move(
          id: entry.key,
          nameFr: raw['name'] as String,
          type: type,
          isFast: raw['fast'] as bool,
          power: (raw['power'] as num?)?.toInt() ?? 0,
          energy: (raw['energy'] as num?)?.toInt() ?? 0,
          effects: <StatChange>[
            for (final e in (raw['effects'] as List<dynamic>?) ?? <dynamic>[])
              _statChange(e as Map<String, dynamic>),
          ],
        ),
      );
    }
    return MoveBook(moves);
  }

  /// Charge `assets/moves.json`.
  static Future<MoveBook> load() async {
    return MoveBook.fromJson(await rootBundle.loadString('assets/moves.json'));
  }

  final Map<String, Move> _byId;

  /// Attaque d'identifiant [id], ou `null`.
  Move? operator [](String id) => _byId[id];

  /// Toutes les attaques, triées par nom.
  List<Move> get all => resolve(_byId.keys);

  /// Attaques connues parmi [ids], triées par nom.
  List<Move> resolve(Iterable<String> ids) {
    final list = <Move>[
      for (final id in ids)
        if (_byId[id] != null) _byId[id]!,
    ]..sort((a, b) => a.nameFr.compareTo(b.nameFr));
    return list;
  }
}

StatChange _statChange(Map<String, dynamic> raw) => StatChange(
      target: raw['target'] == 'opponent' ? StatTarget.opponent : StatTarget.self,
      attack: (raw['atk'] as num?)?.toInt() ?? 0,
      defense: (raw['def'] as num?)?.toInt() ?? 0,
      chance: (raw['chance'] as num?)?.toDouble() ?? 1,
    );
