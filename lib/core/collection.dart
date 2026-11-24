import 'moves.dart';
import 'poke_type.dart';
import 'rank_table.dart';
import 'species_repository.dart';
import 'stats.dart';

/// Ligue d'affichage de la collection.
enum League {
  /// Ligue mini (500 PC).
  little('Mini', '500', 500),

  /// Ligue super (1500 PC).
  great('Super', '1500', 1500),

  /// Ligue hyper (2500 PC).
  ultra('Hyper', '2500', 2500),

  /// Ligue master (sans limite).
  master('Master', 'sans limite', 10000);

  const League(this.label, this.capLabel, this.cpCap);

  /// Nom affiché.
  final String label;

  /// Plafond affiché.
  final String capLabel;

  /// Plafond de PC utilisé pour le classement.
  final int cpCap;
}

/// Un Pokémon enregistré dans la collection.
class CollectionEntry {
  /// Crée une entrée.
  const CollectionEntry({
    required this.id,
    required this.speciesName,
    required this.iv,
    required this.maxLevel,
  });

  /// Lit une entrée enregistrée, ou `null` si elle est illisible.
  static CollectionEntry? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final name = raw['species'];
    final iv = raw['iv'];
    final maxLevel = raw['maxLevel'];
    if (id is! String || name is! String || iv is! List<dynamic>) return null;
    if (iv.length != 3 || iv.any((v) => v is! int || v < 0 || v > 15)) {
      return null;
    }
    return CollectionEntry(
      id: id,
      speciesName: name,
      iv: Iv(iv[0] as int, iv[1] as int, iv[2] as int),
      maxLevel: maxLevel is num ? maxLevel.toDouble() : 51,
    );
  }

  /// Identifiant unique.
  final String id;

  /// Nom de l'espèce dans `species.json`.
  final String speciesName;

  /// IV enregistrés.
  final Iv iv;

  /// Niveau maximal retenu (50, ou 51 en meilleur ami).
  final double maxLevel;

  /// Forme enregistrable en JSON.
  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'species': speciesName,
        'iv': <int>[iv.atk, iv.def, iv.sta],
        'maxLevel': maxLevel,
      };

  /// Vrai si [other] désigne le même Pokémon (espèce, IV et niveau max).
  bool sameAs(CollectionEntry other) =>
      other.speciesName == speciesName &&
      other.iv == iv &&
      other.maxLevel == maxLevel;
}

/// Une entrée de la collection avec son espèce et son classement dans la
/// ligue affichée.
class CollectionRow {
  /// Crée une ligne.
  const CollectionRow({
    required this.entry,
    required this.species,
    required this.rank,
    required this.moves,
  });

  /// Entrée enregistrée.
  final CollectionEntry entry;

  /// Espèce correspondante.
  final Species species;

  /// Classement de ses IV dans la ligue affichée.
  final RankEntry rank;

  /// Attaques que l'espèce peut apprendre.
  final List<Move> moves;
}

/// Ordre d'affichage de la collection.
enum CollectionSort {
  /// Par rang d'IV croissant.
  rank('Rang'),

  /// Par numéro du Pokédex.
  dex('Pokédex'),

  /// Par ordre alphabétique.
  name('Nom'),

  /// Par type principal.
  type('Type');

  const CollectionSort(this.label);

  /// Nom affiché.
  final String label;
}

/// Filtres combinés de la collection (tous doivent être satisfaits).
class CollectionFilter {
  /// Crée un filtre ; sans argument, il laisse tout passer.
  const CollectionFilter({
    this.maxRank,
    this.types = const <PokeType>{},
    this.moveTypes = const <PokeType>{},
    this.moveQuery = '',
  });

  /// Rang maximal accepté, ou `null` pour tous.
  final int? maxRank;

  /// Le Pokémon doit avoir au moins un de ces types (vide : tous).
  final Set<PokeType> types;

  /// Le Pokémon doit pouvoir apprendre une attaque d'au moins un de ces types
  /// (vide : tous).
  final Set<PokeType> moveTypes;

  /// Le Pokémon doit pouvoir apprendre une attaque dont le nom contient ce
  /// texte (vide : tous).
  final String moveQuery;

  /// Nombre de filtres actifs.
  int get activeCount =>
      (maxRank == null ? 0 : 1) +
      (types.isEmpty ? 0 : 1) +
      (moveTypes.isEmpty ? 0 : 1) +
      (moveQuery.trim().isEmpty ? 0 : 1);

  /// Copie avec les champs donnés remplacés ; [clearMaxRank] retire le
  /// filtre de rang.
  CollectionFilter copyWith({
    int? maxRank,
    bool clearMaxRank = false,
    Set<PokeType>? types,
    Set<PokeType>? moveTypes,
    String? moveQuery,
  }) =>
      CollectionFilter(
        maxRank: clearMaxRank ? null : (maxRank ?? this.maxRank),
        types: types ?? this.types,
        moveTypes: moveTypes ?? this.moveTypes,
        moveQuery: moveQuery ?? this.moveQuery,
      );

  /// Vrai si [row] passe tous les filtres.
  bool accepts(CollectionRow row) {
    final max = maxRank;
    if (max != null && row.rank.rank > max) return false;
    if (types.isNotEmpty && !row.species.types.any(types.contains)) {
      return false;
    }
    if (moveTypes.isNotEmpty &&
        !row.moves.any((m) => moveTypes.contains(m.type))) {
      return false;
    }
    final q = normalizeName(moveQuery);
    if (q.isNotEmpty &&
        !row.moves.any((m) => normalizeName(m.nameFr).contains(q))) {
      return false;
    }
    return true;
  }
}

/// Applique [filter] à [rows] puis les trie selon [sort].
List<CollectionRow> filterAndSort(
  Iterable<CollectionRow> rows,
  CollectionFilter filter,
  CollectionSort sort,
) {
  final list = rows.where(filter.accepts).toList();
  int byName(CollectionRow a, CollectionRow b) =>
      normalizeName(a.species.nameFr).compareTo(normalizeName(b.species.nameFr));
  int byRank(CollectionRow a, CollectionRow b) =>
      a.rank.rank.compareTo(b.rank.rank);
  int typeIndex(CollectionRow r) =>
      r.species.types.isEmpty ? PokeType.values.length : r.species.types.first.index;
  list.sort((a, b) {
    final primary = switch (sort) {
      CollectionSort.rank => byRank(a, b),
      CollectionSort.dex => a.species.dex.compareTo(b.species.dex),
      CollectionSort.name => byName(a, b),
      CollectionSort.type => typeIndex(a).compareTo(typeIndex(b)),
    };
    if (primary != 0) return primary;
    final secondary = switch (sort) {
      CollectionSort.rank || CollectionSort.type =>
        a.species.dex.compareTo(b.species.dex),
      CollectionSort.dex || CollectionSort.name => byRank(a, b),
    };
    return secondary != 0 ? secondary : byName(a, b);
  });
  return list;
}
