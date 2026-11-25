import 'rank_table.dart';
import 'stats.dart';

/// Tranche d'un IV dans la recherche de Pokémon GO : 0 (IV 0), 1 (1 à 5),
/// 2 (6 à 10), 3 (11 à 14), 4 (15).
int ivBucket(int iv) {
  if (iv <= 0) return 0;
  if (iv <= 5) return 1;
  if (iv <= 10) return 2;
  if (iv <= 14) return 3;
  return 4;
}

/// Chaîne de recherche du jeu, avec ce qu'elle garde.
class SearchQuery {
  /// Crée la chaîne.
  const SearchQuery({
    required this.text,
    required this.kept,
    required this.total,
  });

  /// Texte à coller dans la recherche de Pokémon GO.
  final String text;

  /// Combinaisons d'IV gardées par la chaîne.
  final int kept;

  /// Combinaisons d'IV possibles.
  final int total;
}

/// Nom de base pour la recherche de famille (`+nom`) : sans forme régionale
/// ni forme entre parenthèses, en minuscules.
String familyName(String nameFr) {
  var name = nameFr;
  final paren = name.indexOf(' (');
  if (paren > 0) name = name.substring(0, paren);
  for (final sep in <String>[" d'", ' de ']) {
    final i = name.indexOf(sep);
    if (i > 0) name = name.substring(0, i);
  }
  return name.trim().toLowerCase();
}

String _range(int lo, int hi, String key) =>
    lo == hi ? '$lo$key' : '$lo-$hi$key';

/// Chaîne qui trouve, dans la famille de [name], tous les Pokémon dont les IV
/// sont parmi les [top] meilleurs de [table] : bornes des tranches d'IV de ce
/// top (le jeu ne cherche que par tranches) et plafond de PC [cpCap] (`null`
/// en ligue Master). Une stat sans contrainte (0 à 4) est omise.
SearchQuery speciesSearch(
  RankTable table, {
  required String name,
  required int top,
  required int? cpCap,
}) {
  final best = table.entries.take(top).toList();
  final lo = <int>[4, 4, 4];
  final hi = <int>[0, 0, 0];
  for (final e in best) {
    final b = <int>[ivBucket(e.iv.atk), ivBucket(e.iv.def), ivBucket(e.iv.sta)];
    for (var i = 0; i < 3; i++) {
      if (b[i] < lo[i]) lo[i] = b[i];
      if (b[i] > hi[i]) hi[i] = b[i];
    }
  }
  bool inBox(Iv iv) {
    final b = <int>[ivBucket(iv.atk), ivBucket(iv.def), ivBucket(iv.sta)];
    for (var i = 0; i < 3; i++) {
      if (b[i] < lo[i] || b[i] > hi[i]) return false;
    }
    return true;
  }

  const keys = <String>['attaque', 'défense', 'PV'];
  final parts = <String>[
    '+${familyName(name)}',
    for (var i = 0; i < 3; i++)
      if (best.isNotEmpty && !(lo[i] == 0 && hi[i] == 4))
        _range(lo[i], hi[i], keys[i]),
    if (cpCap != null) 'PC-$cpCap',
  ];
  return SearchQuery(
    text: parts.join('&'),
    kept: table.entries.where((e) => inBox(e.iv)).length,
    total: table.entries.length,
  );
}

/// Recherche prête à l'emploi.
class SearchPreset {
  /// Crée la recherche.
  const SearchPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.text,
  });

  /// Identifiant stable.
  final String id;

  /// Titre court.
  final String title;

  /// À quoi elle sert.
  final String description;

  /// Texte à coller dans le jeu.
  final String text;
}

/// Recherches utiles pour le PvP, à coller telles quelles dans le jeu.
const List<SearchPreset> searchPresets = <SearchPreset>[
  SearchPreset(
    id: 'great',
    title: 'Candidats Super Ligue',
    description: 'Attaque basse (0 à 5), défense et PV hauts (11 et plus), '
        '1500 PC au plus : le profil des meilleurs IV en Super.',
    text: '0-1attaque&3-4défense&3-4PV&PC-1500',
  ),
  SearchPreset(
    id: 'ultra',
    title: 'Candidats Hyper Ligue',
    description: 'Même profil, 2500 PC au plus.',
    text: '0-1attaque&3-4défense&3-4PV&PC-2500',
  ),
  SearchPreset(
    id: 'little',
    title: 'Candidats Ligue Mini',
    description: 'Même profil, 500 PC au plus (souvent des bébés ou des '
        'premiers stades).',
    text: '0-1attaque&3-4défense&3-4PV&PC-500',
  ),
  SearchPreset(
    id: 'shadow',
    title: 'Obscurs pour le PvP',
    description: "Obscurs au bon profil d'IV : leur bonus d'attaque compense "
        'souvent une défense plus faible.',
    text: 'obscur&0-1attaque&3-4défense&3-4PV',
  ),
  SearchPreset(
    id: 'master',
    title: 'Candidats Master',
    description: 'IV hauts partout (11 et plus) : en Master, plus les IV sont '
        'hauts, mieux c\'est.',
    text: '3-4attaque&3-4défense&3-4PV',
  ),
  SearchPreset(
    id: 'hundo',
    title: '100 %',
    description: 'Les 15/15/15 (4 étoiles à l\'évaluation).',
    text: '4*',
  ),
  SearchPreset(
    id: 'nundo',
    title: '0 %',
    description: 'Les 0/0/0, rares et à garder.',
    text: '0attaque&0défense&0PV',
  ),
];
