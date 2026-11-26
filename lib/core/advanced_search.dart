import 'moves.dart';
import 'poke_type.dart';
import 'search_string.dart';

/// État d'une case du générateur : un appui l'ajoute, un deuxième l'exclut
/// (`!`), un troisième la décoche.
enum Pick {
  /// Non cochée.
  off,

  /// Ajoutée à la recherche.
  include,

  /// Exclue de la recherche (`!`).
  exclude;

  /// État suivant au prochain appui.
  Pick get next => switch (this) {
        Pick.off => Pick.include,
        Pick.include => Pick.exclude,
        Pick.exclude => Pick.off,
      };
}

/// Une case : ses [atoms] sont des termes du jeu reliés par OU (par exemple
/// `@2feu` et `@3feu` pour « attaque chargée Feu »).
class SearchTerm {
  /// Crée la case.
  const SearchTerm(this.id, this.label, this.atoms);

  /// Identifiant stable dans sa rubrique.
  final String id;

  /// Libellé affiché.
  final String label;

  /// Termes du jeu, reliés par OU.
  final List<String> atoms;
}

/// Cases cochées d'une rubrique. Les cases ajoutées sont reliées par OU, ou
/// par ET si [all] ; chaque case exclue est retirée en plus (`!`).
class SearchSection {
  /// Crée la rubrique.
  const SearchSection({
    this.included = const <SearchTerm>[],
    this.excluded = const <SearchTerm>[],
    this.all = false,
  });

  /// Cases ajoutées.
  final List<SearchTerm> included;

  /// Cases exclues.
  final List<SearchTerm> excluded;

  /// Vrai si toutes les cases ajoutées sont exigées (ET), faux si une suffit.
  final bool all;

  /// Clauses de la rubrique, à relier par `&`.
  List<String> clauses() {
    final out = <String>[];
    if (included.isNotEmpty) {
      if (all) {
        for (final t in included) {
          out.add(_unique(t.atoms).join(','));
        }
      } else {
        out.add(_unique(<String>[for (final t in included) ...t.atoms]).join(','));
      }
    }
    for (final t in excluded) {
      for (final a in t.atoms) {
        out.add('!$a');
      }
    }
    return out;
  }
}

List<String> _unique(Iterable<String> items) => <String>{...items}.toList();

/// Chaîne du jeu : les rubriques [sections] dans l'ordre, puis les bornes
/// [ranges] (`null` ignoré), reliées par `&`, sans doublon.
///
/// Dans le jeu, `,` (OU) passe avant `&` (ET) : `feu,eau&chromatique` garde
/// les Pokémon Feu ou Eau, et chromatiques. La rubrique Pokémon doit venir en
/// premier (`+nom` n'est reconnu qu'en tête).
String buildSearch(
  Iterable<SearchSection> sections, {
  Iterable<String?> ranges = const <String?>[],
}) {
  final clauses = <String>[
    for (final s in sections) ...s.clauses(),
    for (final r in ranges)
      if (r != null && r.isNotEmpty) r,
  ];
  return _unique(clauses).join('&');
}

/// Borne d'une stat d'IV en tranches du jeu (0 à 4, voir [ivBucket]) ; `null`
/// si toute l'échelle est gardée.
String? statRange(int lo, int hi, String keyword) {
  final a = lo < hi ? lo : hi;
  final b = lo < hi ? hi : lo;
  if (a <= 0 && b >= 4) return null;
  return a == b ? '$a$keyword' : '$a-$b$keyword';
}

/// Borne numérique du jeu ([key] puis `min-max`, `min-` ou `-max`) ; `null`
/// sans borne.
String? numberRange(String key, int? min, int? max) {
  if (min == null && max == null) return null;
  if (min != null && max != null) {
    final a = min < max ? min : max;
    final b = min < max ? max : min;
    return a == b ? '$key$a' : '$key$a-$b';
  }
  return min != null ? '$key$min-' : '$key-$max';
}

/// Libellé d'une tranche d'IV (0 à 4) : « 0 », « 1-5 », « 6-10 », « 11-14 »,
/// « 15 ».
String ivBucketLabel(int bucket) =>
    const <String>['0', '1-5', '6-10', '11-14', '15'][bucket.clamp(0, 4)];

/// Case d'un type de Pokémon (`feu`).
SearchTerm typeTerm(PokeType t) =>
    SearchTerm(t.id, t.nameFr, <String>[t.nameFr.toLowerCase()]);

/// Emplacement d'attaque recherché.
enum MoveSlot {
  /// N'importe quelle attaque (`@feu`).
  any('Toutes'),

  /// Attaque immédiate (`@1feu`).
  fast('Immédiate'),

  /// Une des deux attaques chargées (`@2feu`, `@3feu`).
  charged('Chargée');

  const MoveSlot(this.label);

  /// Libellé affiché.
  final String label;
}

/// Case d'un type d'attaque pour l'emplacement [slot].
SearchTerm moveTypeTerm(PokeType t, MoveSlot slot) {
  final name = t.nameFr.toLowerCase();
  return SearchTerm(t.id, t.nameFr, switch (slot) {
    MoveSlot.any => <String>['@$name'],
    MoveSlot.fast => <String>['@1$name'],
    MoveSlot.charged => <String>['@2$name', '@3$name'],
  });
}

/// Case d'une attaque par son nom (`@rapace`).
SearchTerm moveNameTerm(Move m) =>
    SearchTerm(m.id, m.nameFr, <String>['@${m.nameFr.toLowerCase()}']);

/// Case d'un Pokémon : son nom, ou toute sa famille si [family] (`+nom`).
SearchTerm speciesTerm(String nameFr, {required bool family}) {
  final name = familyName(nameFr);
  return family
      ? SearchTerm('+$name', 'Famille $name', <String>['+$name'])
      : SearchTerm(name, name, <String>[name]);
}

SearchTerm _word(String atom, String label) =>
    SearchTerm(atom, label, <String>[atom]);

/// Légendaire, fabuleux, ultra-chimère.
final List<SearchTerm> categoryTerms = <SearchTerm>[
  _word('légendaire', 'Légendaire'),
  _word('fabuleux', 'Fabuleux'),
  _word('ultra-chimère', 'Ultra-chimère'),
];

/// Chanceux, shiny, obscur, purifié, costume (Pokémon d'événement).
final List<SearchTerm> statusTerms = <SearchTerm>[
  _word('chanceux', 'Chanceux'),
  _word('chromatique', 'Shiny'),
  _word('obscur', 'Obscur'),
  _word('purifié', 'Purifié'),
];

/// Tailles XXS à XXL.
final List<SearchTerm> sizeTerms = <SearchTerm>[
  for (final s in <String>['xxs', 'xs', 'xl', 'xxl']) _word(s, s.toUpperCase()),
];

/// Évaluation en étoiles, de 0★ à 4★.
final List<SearchTerm> starTerms = <SearchTerm>[
  for (var i = 0; i <= 4; i++) _word('$i*', '$i★'),
];

/// Attaque élite ou spéciale (non apprenable par CT).
final SearchTerm eliteTerm = _word('@spécial', 'Attaque élite');

/// Cases d'une rubrique et leur état ; les cases ajoutées à la main (Pokémon,
/// attaques) gardent leur ordre d'ajout.
class PickGroup {
  /// Crée la rubrique avec ses cases fixes [terms].
  PickGroup(List<SearchTerm> terms, {this.exclusive = false})
      : _terms = <String, SearchTerm>{for (final t in terms) t.id: t};

  final Map<String, SearchTerm> _terms;

  /// Vrai si les cases s'excluent (taille, évaluation…) : les cases ajoutées
  /// sont toujours reliées par OU, ET n'aurait aucun résultat.
  final bool exclusive;
  final Map<String, Pick> _picks = <String, Pick>{};

  /// Vrai pour relier les cases ajoutées par ET au lieu de OU.
  bool all = false;

  /// Cases, dans l'ordre.
  List<SearchTerm> get terms => _terms.values.toList();

  /// État de la case [id].
  Pick pickOf(String id) => _picks[id] ?? Pick.off;

  /// Passe la case [id] à l'état suivant.
  void cycle(String id) => _picks[id] = pickOf(id).next;

  /// Décoche la case [id].
  void uncheck(String id) => _picks.remove(id);

  /// Ajoute la case [term] (si absente) et la coche.
  void add(SearchTerm term) {
    _terms.putIfAbsent(term.id, () => term);
    _picks[term.id] = Pick.include;
  }

  /// Retire la case [id] (cases ajoutées à la main).
  void remove(String id) {
    _terms.remove(id);
    _picks.remove(id);
  }

  /// Décoche tout et revient au OU ; [dropTerms] retire aussi les cases.
  void clear({bool dropTerms = false}) {
    _picks.clear();
    all = false;
    if (dropTerms) _terms.clear();
  }

  /// Nombre de cases ajoutées.
  int get includedCount =>
      _terms.keys.where((id) => pickOf(id) == Pick.include).length;

  /// Nombre de cases cochées (ajoutées ou exclues).
  int get activeCount =>
      _terms.keys.where((id) => pickOf(id) != Pick.off).length;

  /// Rubrique de recherche correspondante.
  SearchSection section() => SearchSection(
        included: <SearchTerm>[
          for (final t in _terms.values)
            if (pickOf(t.id) == Pick.include) t,
        ],
        excluded: <SearchTerm>[
          for (final t in _terms.values)
            if (pickOf(t.id) == Pick.exclude) t,
        ],
        all: all,
      );
}

(int, int) starTotal(int star) => (0, 0);

(int, int) ivTotalRange(List<(int, int)> buckets) => (0, 0);

bool starPossible(int star, List<(int, int)> buckets) => true;

(int, int) starBucketLimits(Set<int> stars) => (0, 4);

List<String> ivRangeClauses(List<(int, int)> buckets, Set<int> stars) =>
    const <String>[];
