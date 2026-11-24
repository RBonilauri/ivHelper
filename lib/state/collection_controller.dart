import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/collection.dart';
import '../core/moves.dart';
import '../core/rank_table.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';
import '../settings/settings_controller.dart';

/// État de la collection : Pokémon enregistrés, filtres et tri.
class CollectionController extends ChangeNotifier {
  /// Crée le contrôleur.
  CollectionController({
    required this.repository,
    required this.moves,
    required this.store,
  });

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Attaques connues.
  final MoveBook moves;

  /// Stockage de la collection.
  final SettingsStore store;

  final List<CollectionEntry> _entries = <CollectionEntry>[];
  final Map<String, RankTable> _tables = <String, RankTable>{};
  League _league = League.great;
  CollectionFilter _filter = const CollectionFilter();
  CollectionSort _sort = CollectionSort.rank;
  bool _disposed = false;
  int _counter = 0;

  /// Pokémon enregistrés, du plus ancien au plus récent.
  List<CollectionEntry> get entries =>
      List<CollectionEntry>.unmodifiable(_entries);

  /// Ligue affichée.
  League get league => _league;

  /// Filtres actifs.
  CollectionFilter get filter => _filter;

  /// Tri actif.
  CollectionSort get sort => _sort;

  /// Noms des espèces possédées (pour la méta).
  Set<String> get ownedSpecies =>
      <String>{for (final e in _entries) e.speciesName};

  /// Lignes de la ligue affichée, filtrées et triées.
  List<CollectionRow> get visibleRows => filterAndSort(_rows(), _filter, _sort);

  /// Nombre de Pokémon enregistrés dont l'espèce est connue.
  int get total => _rows().length;

  /// Change la ligue affichée.
  void setLeague(League value) {
    _league = value;
    notifyListeners();
  }

  /// Change les filtres.
  void setFilter(CollectionFilter value) {
    _filter = value;
    notifyListeners();
  }

  /// Change le tri.
  void setSort(CollectionSort value) {
    _sort = value;
    notifyListeners();
  }

  /// Enregistre [species] avec ses [iv] ; renvoie faux s'il y est déjà.
  bool add(Species species, Iv iv, double maxLevel) {
    final entry = CollectionEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
      speciesName: species.nameFr,
      iv: iv,
      maxLevel: maxLevel,
    );
    if (_entries.any(entry.sameAs)) return false;
    _entries.add(entry);
    _changed();
    return true;
  }

  /// Retire l'entrée [id].
  void remove(String id) {
    _entries.removeWhere((e) => e.id == id);
    _changed();
  }

  /// Remet [entry] (après une annulation).
  void restore(CollectionEntry entry) {
    if (_entries.any((e) => e.id == entry.id)) return;
    _entries.add(entry);
    _changed();
  }

  /// Recharge la collection enregistrée ; ignore une sauvegarde illisible.
  Future<void> load() async {
    final raw = await store.readCollection();
    if (raw == null || _disposed) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! List<dynamic>) return;
    _entries
      ..clear()
      ..addAll(<CollectionEntry>[
        for (final item in decoded)
          if (CollectionEntry.fromJson(item) != null)
            CollectionEntry.fromJson(item)!,
      ]);
    notifyListeners();
  }

  List<CollectionRow> _rows() {
    final rows = <CollectionRow>[];
    for (final e in _entries) {
      final species = repository.findByName(e.speciesName);
      if (species == null || species.nameFr != e.speciesName) continue;
      final key = '${species.nameFr}|${e.maxLevel}|${_league.cpCap}';
      final table = _tables[key] ??= buildRankTable(
        species.base,
        cpCap: _league.cpCap,
        maxLevel: e.maxLevel,
      );
      rows.add(
        CollectionRow(
          entry: e,
          species: species,
          rank: table.entryFor(e.iv),
          moves: moves.resolve(<String>[
            ...species.fastMoves,
            ...species.chargedMoves,
          ]),
        ),
      );
    }
    return rows;
  }

  void _changed() {
    if (_disposed) return;
    notifyListeners();
    unawaited(
      store.writeCollection(
        jsonEncode(<Map<String, Object>>[
          for (final e in _entries) e.toJson(),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
