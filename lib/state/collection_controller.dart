import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/collection.dart';
import '../core/moves.dart';
import '../core/rank_table.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';
import '../settings/settings_controller.dart';

/// Affichage de la collection.
enum CollectionView {
  /// Une ligne par Pokémon.
  list,

  /// Une mosaïque de cases.
  grid,
}

/// Options choisies dans le menu d'enregistrement.
class SaveOptions {
  /// Crée des options.
  const SaveOptions({
    required this.league,
    this.fastMove,
    this.chargedMove1,
    this.chargedMove2,
    this.shadow = ShadowState.none,
    this.size = PokeSize.none,
    this.lucky = false,
    this.shiny = false,
    this.costume = false,
  });

  /// Options d'une entrée existante.
  factory SaveOptions.of(CollectionEntry e) => SaveOptions(
        league: e.league,
        fastMove: e.fastMove,
        chargedMove1: e.chargedMove1,
        chargedMove2: e.chargedMove2,
        shadow: e.shadow,
        size: e.size,
        lucky: e.lucky,
        shiny: e.shiny,
        costume: e.costume,
      );

  /// Ligue du tag.
  final League league;

  /// Attaque immédiate.
  final String? fastMove;

  /// Première attaque chargée.
  final String? chargedMove1;

  /// Seconde attaque chargée.
  final String? chargedMove2;

  /// Obscur ou purifié.
  final ShadowState shadow;

  /// Taille notable.
  final PokeSize size;

  /// Chanceux.
  final bool lucky;

  /// Chromatique.
  final bool shiny;

  /// Costumé.
  final bool costume;
}

/// État de la collection : Pokémon enregistrés, filtres, tri et affichage.
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
  CollectionFilter _filter = const CollectionFilter();
  CollectionSort _sort = CollectionSort.rank;
  CollectionView _view = CollectionView.list;
  bool _disposed = false;
  int _counter = 0;

  /// Pokémon enregistrés, du plus ancien au plus récent.
  List<CollectionEntry> get entries =>
      List<CollectionEntry>.unmodifiable(_entries);

  /// Filtres actifs.
  CollectionFilter get filter => _filter;

  /// Tri actif.
  CollectionSort get sort => _sort;

  /// Affichage actif.
  CollectionView get view => _view;

  /// Noms des espèces possédées (pour la méta).
  Set<String> get ownedSpecies =>
      <String>{for (final e in _entries) e.speciesName};

  /// Lignes filtrées et triées.
  List<CollectionRow> get visibleRows => filterAndSort(_rows(), _filter, _sort);

  /// Comme [visibleRows], avec le rang méta [metaRankOf] pour le tri
  /// « Rang méta ».
  List<CollectionRow> visibleRowsWith(MetaRankOf? metaRankOf) =>
      filterAndSort(_rows(), _filter, _sort, metaRankOf: metaRankOf);

  /// Toutes les lignes, sans filtre ni tri.
  List<CollectionRow> get visibleRowsUnfiltered => _rows();

  /// Nombre de Pokémon enregistrés dont l'espèce est connue.
  int get total => _rows().length;

  /// Ligne de l'entrée [id], ou `null`.
  CollectionRow? rowOf(String id) {
    for (final r in _rows()) {
      if (r.entry.id == id) return r;
    }
    return null;
  }

  bool _filtersOpen = false;

  /// Vrai si le panneau des filtres est ouvert (fermé par défaut).
  bool get filtersOpen => _filtersOpen;

  /// Ouvre ou ferme le panneau des filtres.
  void setFiltersOpen(bool value) {
    _filtersOpen = value;
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

  /// Change l'affichage.
  void setView(CollectionView value) {
    _view = value;
    notifyListeners();
  }

  /// Classement des [iv] de [species] dans [league] au niveau max [maxLevel].
  RankEntry rankFor(Species species, Iv iv, double maxLevel, League league) {
    final key = '${species.nameFr}|$maxLevel|${league.cpCap}';
    final table = _tables[key] ??= buildRankTable(
      species.base,
      cpCap: league.cpCap,
      maxLevel: maxLevel,
    );
    return table.entryFor(iv);
  }

  /// Enregistre [species] avec ses [iv] et les [options] ; le rang dans la
  /// ligue choisie est figé maintenant.
  CollectionEntry add(
    Species species,
    Iv iv,
    double maxLevel,
    SaveOptions options,
  ) {
    final entry = _build(
      '${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
      species,
      iv,
      maxLevel,
      options,
    );
    _entries.add(entry);
    _changed();
    return entry;
  }

  /// Remplace les options de l'entrée [id] ; le rang est recalculé si la
  /// ligue change.
  void update(String id, SaveOptions options) {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final old = _entries[i];
    final species = repository.findByName(old.speciesName);
    if (species == null) return;
    final fresh = _build(id, species, old.iv, old.maxLevel, options);
    _entries[i] = old.league == options.league
        ? CollectionEntry(
            id: id,
            speciesName: old.speciesName,
            iv: old.iv,
            maxLevel: old.maxLevel,
            league: old.league,
            rank: old.rank,
            percent: old.percent,
            cp: old.cp,
            level: old.level,
            fastMove: fresh.fastMove,
            chargedMove1: fresh.chargedMove1,
            chargedMove2: fresh.chargedMove2,
            shadow: fresh.shadow,
            size: fresh.size,
            lucky: fresh.lucky,
            shiny: fresh.shiny,
            costume: fresh.costume,
            favorite: old.favorite,
          )
        : fresh.withFavorite(old.favorite);
    _changed();
  }

  /// Ajoute ou retire l'entrée [id] des favoris.
  void toggleFavorite(String id) {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _entries[i] = _entries[i].withFavorite(!_entries[i].favorite);
    _changed();
  }

  /// Retire l'entrée [id].
  void remove(String id) {
    _entries.removeWhere((e) => e.id == id);
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
    var migrated = false;
    _entries.clear();
    for (final item in decoded) {
      final entry = CollectionEntry.fromJson(item) ?? _legacy(item);
      if (entry == null) continue;
      if (CollectionEntry.fromJson(item) == null) migrated = true;
      _entries.add(entry);
    }
    if (migrated) {
      _changed();
    } else {
      notifyListeners();
    }
  }

  /// Entrée de l'ancien format (sans ligue ni rang) : rangée en ligue super,
  /// rang calculé maintenant.
  CollectionEntry? _legacy(Object? item) {
    if (item is! Map<String, dynamic>) return null;
    final id = item['id'];
    final name = item['species'];
    final iv = item['iv'];
    if (id is! String || name is! String || iv is! List<dynamic>) return null;
    if (iv.length != 3 || iv.any((v) => v is! int || v < 0 || v > 15)) {
      return null;
    }
    final species = repository.findByName(name);
    if (species == null || species.nameFr != name) return null;
    final maxLevel = item['maxLevel'];
    return _build(
      id,
      species,
      Iv(iv[0] as int, iv[1] as int, iv[2] as int),
      maxLevel is num ? maxLevel.toDouble() : 51,
      const SaveOptions(league: League.great),
    );
  }

  CollectionEntry _build(
    String id,
    Species species,
    Iv iv,
    double maxLevel,
    SaveOptions o,
  ) {
    final r = rankFor(species, iv, maxLevel, o.league);
    String? valid(String? moveId, List<String> allowed) =>
        moveId != null && allowed.contains(moveId) ? moveId : null;
    return CollectionEntry(
      id: id,
      speciesName: species.nameFr,
      iv: iv,
      maxLevel: maxLevel,
      league: o.league,
      rank: r.rank,
      percent: r.percent,
      cp: r.cp,
      level: r.level,
      fastMove: valid(o.fastMove, species.fastMoves),
      chargedMove1: valid(o.chargedMove1, species.chargedMoves),
      chargedMove2: o.chargedMove2 == o.chargedMove1
          ? null
          : valid(o.chargedMove2, species.chargedMoves),
      shadow: o.shadow,
      size: o.size,
      lucky: o.lucky,
      shiny: o.shiny,
      costume: o.costume,
    );
  }

  List<CollectionRow> _rows() {
    final rows = <CollectionRow>[];
    for (final e in _entries) {
      final species = repository.findByName(e.speciesName);
      if (species == null || species.nameFr != e.speciesName) continue;
      rows.add(
        CollectionRow(
          entry: e,
          species: species,
          recordedMoves: <Move>[
            for (final id in e.moveIds)
              if (moves[id] != null) moves[id]!,
          ],
          learnableMoves: moves.resolve(<String>[
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
        jsonEncode(<Map<String, Object?>>[
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
