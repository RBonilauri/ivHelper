import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/moves.dart';
import '../core/species_repository.dart';
import '../core/team_analysis.dart';
import '../settings/settings_controller.dart';

/// Un emplacement de l'équipe : espèce, attaque immédiate, deux chargées.
@immutable
class TeamSlot {
  /// Crée un emplacement.
  const TeamSlot({this.species, this.fast, this.charged1, this.charged2});

  /// Emplacement vide.
  static const TeamSlot empty = TeamSlot();

  /// Espèce choisie, ou `null`.
  final Species? species;

  /// Attaque immédiate choisie.
  final Move? fast;

  /// Première attaque chargée.
  final Move? charged1;

  /// Seconde attaque chargée (facultative).
  final Move? charged2;

  /// Attaques choisies, sans doublon.
  List<Move> get moves {
    final list = <Move>[];
    for (final m in <Move?>[fast, charged1, charged2]) {
      if (m != null && !list.any((e) => e.id == m.id)) list.add(m);
    }
    return list;
  }
}

/// État du team builder : trois emplacements, enregistrés à chaque changement.
class TeamController extends ChangeNotifier {
  /// Crée le contrôleur.
  TeamController({
    required this.repository,
    required this.moves,
    required this.store,
  });

  /// Nombre de Pokémon dans une équipe.
  static const int size = 3;

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Attaques connues.
  final MoveBook moves;

  /// Stockage de l'équipe.
  final SettingsStore store;

  final List<TeamSlot> _slots =
      List<TeamSlot>.filled(size, TeamSlot.empty, growable: false);
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Les trois emplacements.
  List<TeamSlot> get slots => List<TeamSlot>.unmodifiable(_slots);

  /// Attaques immédiates possibles pour l'emplacement [index].
  List<Move> fastOptions(int index) =>
      moves.resolve(_slots[index].species?.fastMoves ?? const <String>[]);

  /// Attaques chargées possibles pour l'emplacement [index].
  List<Move> chargedOptions(int index) =>
      moves.resolve(_slots[index].species?.chargedMoves ?? const <String>[]);

  /// Profil défensif de l'emplacement [index], ou `null` s'il est vide.
  DefenseProfile? defenseOf(int index) {
    final s = _slots[index].species;
    return s == null ? null : DefenseProfile(s.types);
  }

  /// Profil offensif de l'emplacement [index], ou `null` sans attaque.
  OffenseProfile? offenseOf(int index) {
    final m = _slots[index].moves;
    return m.isEmpty ? null : OffenseProfile(m);
  }

  /// Bilan de l'équipe sur les emplacements renseignés.
  TeamSummary get summary => TeamSummary(
        defenses: <DefenseProfile>[
          for (var i = 0; i < size; i++)
            if (defenseOf(i) != null) defenseOf(i)!,
        ],
        offenses: <OffenseProfile>[
          for (var i = 0; i < size; i++)
            if (offenseOf(i) != null) offenseOf(i)!,
        ],
      );

  /// Place [species] dans l'emplacement [index] (`null` pour le vider).
  ///
  /// Les attaques sont remises à zéro.
  void setSpecies(int index, Species? species) {
    _slots[index] = TeamSlot(species: species);
    _changed();
  }

  /// Choisit l'attaque immédiate de l'emplacement [index].
  void setFast(int index, Move? move) {
    final s = _slots[index];
    _slots[index] = TeamSlot(
      species: s.species,
      fast: move,
      charged1: s.charged1,
      charged2: s.charged2,
    );
    _changed();
  }

  /// Choisit l'attaque chargée numéro [which] (1 ou 2) de l'emplacement
  /// [index].
  void setCharged(int index, int which, Move? move) {
    final s = _slots[index];
    _slots[index] = TeamSlot(
      species: s.species,
      fast: s.fast,
      charged1: which == 1 ? move : s.charged1,
      charged2: which == 2 ? move : s.charged2,
    );
    _changed();
  }

  /// Recharge l'équipe enregistrée ; ignore une sauvegarde illisible.
  Future<void> load() async {
    final raw = await store.readTeam();
    if (raw == null || _disposed) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! List<dynamic>) return;
    for (var i = 0; i < size && i < decoded.length; i++) {
      final m = decoded[i];
      if (m is! Map<String, dynamic>) continue;
      final name = m['species'];
      if (name is! String) continue;
      final species = repository.findByName(name);
      if (species == null || species.nameFr != name) continue;
      Move? pick(String key, List<String> allowed) {
        final id = m[key];
        return id is String && allowed.contains(id) ? moves[id] : null;
      }

      _slots[i] = TeamSlot(
        species: species,
        fast: pick('fast', species.fastMoves),
        charged1: pick('charged1', species.chargedMoves),
        charged2: pick('charged2', species.chargedMoves),
      );
    }
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    final data = <Map<String, String?>>[
      for (final s in _slots)
        <String, String?>{
          'species': s.species?.nameFr,
          'fast': s.fast?.id,
          'charged1': s.charged1?.id,
          'charged2': s.charged2?.id,
        },
    ];
    unawaited(store.writeTeam(jsonEncode(data)));
  }
}
