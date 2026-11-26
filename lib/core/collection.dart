import 'league.dart';
import 'moves.dart';
import 'poke_type.dart';
import 'species_repository.dart';
import 'stats.dart';

export 'league.dart';

/// Forme obscure ou purifiée (facultatif).
enum ShadowState {
  /// Ni obscur ni purifié.
  none('none', 'Normal'),

  /// Obscur.
  shadow('shadow', 'Obscur'),

  /// Purifié.
  purified('purified', 'Purifié');

  const ShadowState(this.key, this.label);

  /// Clé enregistrée.
  final String key;

  /// Nom affiché.
  final String label;
}

/// Taille notable (facultatif).
enum PokeSize {
  /// Pas de taille notable.
  none('none', ''),

  /// XXS.
  xxs('xxs', 'XXS'),

  /// XS.
  xs('xs', 'XS'),

  /// XL.
  xl('xl', 'XL'),

  /// XXL.
  xxl('xxl', 'XXL');

  const PokeSize(this.key, this.label);

  /// Clé enregistrée.
  final String key;

  /// Nom affiché.
  final String label;
}

ShadowState _shadowOf(Object? key) {
  for (final v in ShadowState.values) {
    if (v.key == key) return v;
  }
  return ShadowState.none;
}

PokeSize _sizeOf(Object? key) {
  for (final v in PokeSize.values) {
    if (v.key == key) return v;
  }
  return PokeSize.none;
}

/// Un Pokémon enregistré, avec le rang de ses IV figé à l'enregistrement.
class CollectionEntry {
  /// Crée une entrée.
  const CollectionEntry({
    required this.id,
    required this.speciesName,
    required this.iv,
    required this.maxLevel,
    required this.league,
    required this.rank,
    required this.percent,
    required this.cp,
    required this.level,
    this.fastMove,
    this.chargedMove1,
    this.chargedMove2,
    this.shadow = ShadowState.none,
    this.size = PokeSize.none,
    this.lucky = false,
    this.shiny = false,
    this.costume = false,
    this.favorite = false,
  });

  /// Lit une entrée enregistrée, ou `null` si elle est illisible.
  static CollectionEntry? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final name = raw['species'];
    final iv = raw['iv'];
    final rank = raw['rank'];
    final league = League.fromKey(raw['league']);
    if (id is! String || name is! String || iv is! List<dynamic>) return null;
    if (iv.length != 3 || iv.any((v) => v is! int || v < 0 || v > 15)) {
      return null;
    }
    if (rank is! int || league == null) return null;
    String? str(String key) {
      final v = raw[key];
      return v is String ? v : null;
    }

    double dbl(String key, double fallback) {
      final v = raw[key];
      return v is num ? v.toDouble() : fallback;
    }

    final cp = raw['cp'];
    return CollectionEntry(
      id: id,
      speciesName: name,
      iv: Iv(iv[0] as int, iv[1] as int, iv[2] as int),
      maxLevel: dbl('maxLevel', 51),
      league: league,
      rank: rank,
      percent: dbl('percent', 0),
      cp: cp is int ? cp : 0,
      level: dbl('level', 1),
      fastMove: str('fast'),
      chargedMove1: str('charged1'),
      chargedMove2: str('charged2'),
      shadow: _shadowOf(raw['shadow']),
      size: _sizeOf(raw['size']),
      lucky: raw['lucky'] == true,
      shiny: raw['shiny'] == true,
      costume: raw['costume'] == true,
      favorite: raw['favorite'] == true,
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

  /// Ligue choisie à l'enregistrement.
  final League league;

  /// Rang des IV dans [league] à l'enregistrement.
  final int rank;

  /// Pourcentage du meilleur produit de stats à l'enregistrement.
  final double percent;

  /// PC au niveau optimal de [league].
  final int cp;

  /// Niveau optimal dans [league].
  final double level;

  /// Attaque immédiate (identifiant), facultative.
  final String? fastMove;

  /// Première attaque chargée (identifiant), facultative.
  final String? chargedMove1;

  /// Seconde attaque chargée (identifiant), facultative.
  final String? chargedMove2;

  /// Obscur ou purifié.
  final ShadowState shadow;

  /// Taille notable.
  final PokeSize size;

  /// Pokémon chanceux.
  final bool lucky;

  /// Pokémon chromatique.
  final bool shiny;

  /// Pokémon costumé.
  final bool costume;

  /// Pokémon mis en favori.
  final bool favorite;

  /// Copie avec [favorite] remplacé.
  CollectionEntry withFavorite(bool value) => CollectionEntry(
        id: id,
        speciesName: speciesName,
        iv: iv,
        maxLevel: maxLevel,
        league: league,
        rank: rank,
        percent: percent,
        cp: cp,
        level: level,
        fastMove: fastMove,
        chargedMove1: chargedMove1,
        chargedMove2: chargedMove2,
        shadow: shadow,
        size: size,
        lucky: lucky,
        shiny: shiny,
        costume: costume,
        favorite: value,
      );

  /// Vrai si c'est le meilleur rang possible dans sa ligue.
  bool get isRankOne => rank == 1;

  /// Identifiants des attaques enregistrées.
  List<String> get moveIds => <String>[
        for (final m in <String?>[fastMove, chargedMove1, chargedMove2])
          if (m != null) m,
      ];

  /// Forme enregistrable en JSON.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'species': speciesName,
        'iv': <int>[iv.atk, iv.def, iv.sta],
        'maxLevel': maxLevel,
        'league': league.key,
        'rank': rank,
        'percent': percent,
        'cp': cp,
        'level': level,
        'fast': fastMove,
        'charged1': chargedMove1,
        'charged2': chargedMove2,
        'shadow': shadow.key,
        'size': size.key,
        'lucky': lucky,
        'shiny': shiny,
        'costume': costume,
        'favorite': favorite,
      };
}

/// Une entrée de la collection avec son espèce et ses attaques.
class CollectionRow {
  /// Crée une ligne.
  const CollectionRow({
    required this.entry,
    required this.species,
    required this.recordedMoves,
    required this.learnableMoves,
  });

  /// Entrée enregistrée.
  final CollectionEntry entry;

  /// Espèce correspondante.
  final Species species;

  /// Attaques enregistrées.
  final List<Move> recordedMoves;

  /// Attaques que l'espèce peut apprendre.
  final List<Move> learnableMoves;

  /// Attaques prises en compte par le filtre : celles enregistrées, à défaut
  /// celles que l'espèce peut apprendre.
  List<Move> get filterMoves =>
      recordedMoves.isNotEmpty ? recordedMoves : learnableMoves;
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
  type('Type'),

  /// Favoris d'abord, puis par rang d'IV.
  favorite('Favoris'),

  /// Par rang dans la méta de la ligue du tag (non classés à la fin).
  metaRank('Rang méta');

  const CollectionSort(this.label);

  /// Nom affiché.
  final String label;
}

/// Seuils du filtre de rang d'IV (`null` : tous).
const List<int?> rankThresholds = <int?>[null, 10, 50];

/// Filtres combinés de la collection (tous doivent être satisfaits).
class CollectionFilter {
  /// Crée un filtre ; sans argument, il laisse tout passer.
  const CollectionFilter({
    this.league,
    this.maxRank,
    this.maxMetaRank,
    this.types = const <PokeType>{},
    this.moveTypes = const <PokeType>{},
    this.moveQuery = '',
    this.favoritesOnly = false,
  });

  /// Ligue du tag, ou `null` pour toutes.
  final League? league;

  /// Rang maximal accepté dans la ligue du tag, ou `null` pour tous.
  final int? maxRank;

  /// Rang méta maximal dans la ligue du tag, ou `null` pour tous.
  final int? maxMetaRank;

  /// Le Pokémon doit avoir au moins un de ces types (vide : tous).
  final Set<PokeType> types;

  /// Il doit avoir une attaque d'au moins un de ces types (vide : tous).
  final Set<PokeType> moveTypes;

  /// Il doit avoir une attaque dont le nom contient ce texte (vide : tous).
  final String moveQuery;

  /// Vrai pour ne garder que les favoris.
  final bool favoritesOnly;

  /// Nombre de filtres actifs.
  int get activeCount =>
      (league == null ? 0 : 1) +
      (maxRank == null ? 0 : 1) +
      (types.isEmpty ? 0 : 1) +
      (moveTypes.isEmpty ? 0 : 1) +
      (moveQuery.trim().isEmpty ? 0 : 1) +
      (favoritesOnly ? 1 : 0);

  /// Copie avec les champs donnés remplacés ; [clearLeague] et [clearMaxRank]
  /// retirent ces filtres.
  CollectionFilter copyWith({
    League? league,
    bool clearLeague = false,
    int? maxRank,
    bool clearMaxRank = false,
    int? maxMetaRank,
    bool clearMaxMetaRank = false,
    Set<PokeType>? types,
    Set<PokeType>? moveTypes,
    String? moveQuery,
    bool? favoritesOnly,
  }) =>
      CollectionFilter(
        league: clearLeague ? null : (league ?? this.league),
        maxRank: clearMaxRank ? null : (maxRank ?? this.maxRank),
        types: types ?? this.types,
        moveTypes: moveTypes ?? this.moveTypes,
        moveQuery: moveQuery ?? this.moveQuery,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );

  /// Vrai si [row] passe tous les filtres.
  bool accepts(CollectionRow row) {
    final e = row.entry;
    if (favoritesOnly && !e.favorite) return false;
    if (league != null && e.league != league) return false;
    final max = maxRank;
    if (max != null && e.rank > max) return false;
    if (types.isNotEmpty && !row.species.types.any(types.contains)) {
      return false;
    }
    final moves = row.filterMoves;
    if (moveTypes.isNotEmpty && !moves.any((m) => moveTypes.contains(m.type))) {
      return false;
    }
    final q = normalizeName(moveQuery);
    if (q.isNotEmpty &&
        !moves.any((m) => normalizeName(m.nameFr).contains(q))) {
      return false;
    }
    return true;
  }
}

/// Rang méta d'une entrée dans la ligue de son tag, ou `null` si non classée.
typedef MetaRankOf = int? Function(CollectionEntry entry);

/// Applique [filter] à [rows] puis les trie selon [sort] ; [metaRankOf] sert
/// au tri par rang méta (sans lui, tous sont « non classés »).
List<CollectionRow> filterAndSort(
  Iterable<CollectionRow> rows,
  CollectionFilter filter,
  CollectionSort sort, {
  MetaRankOf? metaRankOf,
}) {
  final list = rows.where(filter.accepts).toList();
  int byName(CollectionRow a, CollectionRow b) => normalizeName(
        a.species.nameFr,
      ).compareTo(normalizeName(b.species.nameFr));
  int byRank(CollectionRow a, CollectionRow b) =>
      a.entry.rank.compareTo(b.entry.rank);
  int byDex(CollectionRow a, CollectionRow b) =>
      a.species.dex.compareTo(b.species.dex);
  int byFavorite(CollectionRow a, CollectionRow b) =>
      (b.entry.favorite ? 1 : 0).compareTo(a.entry.favorite ? 1 : 0);
  final metaRanks = <String, int?>{
    if (sort == CollectionSort.metaRank && metaRankOf != null)
      for (final r in list) r.entry.id: metaRankOf(r.entry),
  };
  int byMeta(CollectionRow a, CollectionRow b) {
    final ra = metaRanks[a.entry.id];
    final rb = metaRanks[b.entry.id];
    if (ra == null && rb == null) return 0;
    if (ra == null) return 1;
    if (rb == null) return -1;
    return ra.compareTo(rb);
  }

  int typeIndex(CollectionRow r) => r.species.types.isEmpty
      ? PokeType.values.length
      : r.species.types.first.index;
  list.sort((a, b) {
    final primary = switch (sort) {
      CollectionSort.rank => byRank(a, b),
      CollectionSort.dex => byDex(a, b),
      CollectionSort.name => byName(a, b),
      CollectionSort.type => typeIndex(a).compareTo(typeIndex(b)),
      CollectionSort.favorite => byFavorite(a, b),
      CollectionSort.metaRank => byMeta(a, b),
    };
    if (primary != 0) return primary;
    final secondary = switch (sort) {
      CollectionSort.rank || CollectionSort.type => byDex(a, b),
      CollectionSort.favorite || CollectionSort.metaRank => byRank(a, b),
      CollectionSort.dex || CollectionSort.name => byRank(a, b),
    };
    return secondary != 0 ? secondary : byName(a, b);
  });
  return list;
}
