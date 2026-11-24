import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'poke_type.dart';

/// Une attaque de Pokémon GO.
class Move {
  /// Crée une attaque.
  const Move({
    required this.id,
    required this.nameFr,
    required this.type,
    required this.isFast,
    this.power = 0,
  });

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

  /// Attaques connues parmi [ids], triées par nom.
  List<Move> resolve(Iterable<String> ids) {
    final list = <Move>[
      for (final id in ids)
        if (_byId[id] != null) _byId[id]!,
    ]..sort((a, b) => a.nameFr.compareTo(b.nameFr));
    return list;
  }
}
