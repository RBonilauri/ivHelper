import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'stats.dart';

/// Une espèce (ou une forme régionale) avec ses stats de base.
class Species {
  /// Crée une espèce.
  const Species({required this.dex, required this.nameFr, required this.base});

  /// Numéro du Pokédex national.
  final int dex;

  /// Nom français, avec la forme régionale le cas échéant.
  final String nameFr;

  /// Stats de base de l'espèce.
  final BaseStats base;
}

/// Recherche d'espèces par nom (tolérante aux fautes) ou par numéro.
class SpeciesRepository {
  /// Crée un dépôt à partir de la liste [all], formes de base d'abord.
  SpeciesRepository(List<Species> all)
      : all = List<Species>.unmodifiable(all),
        _normalized = <String>[for (final s in all) _normalize(s.nameFr)];

  /// Lit la liste des espèces depuis un JSON produit par
  /// `tool/build_species.py`.
  factory SpeciesRepository.fromJson(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return SpeciesRepository(<Species>[
      for (final raw in list)
        Species(
          dex: (raw as Map<String, dynamic>)['dex'] as int,
          nameFr: raw['name'] as String,
          base: BaseStats(
            raw['atk'] as int,
            raw['def'] as int,
            raw['sta'] as int,
          ),
        ),
    ]);
  }

  /// Charge `assets/species.json`.
  static Future<SpeciesRepository> load() async {
    return SpeciesRepository.fromJson(
      await rootBundle.loadString('assets/species.json'),
    );
  }

  /// Toutes les espèces connues.
  final List<Species> all;

  final List<String> _normalized;

  /// Espèce de base portant le numéro [dex], ou `null` si inconnu.
  Species? findByDex(int dex) {
    for (final s in all) {
      if (s.dex == dex) return s;
    }
    return null;
  }

  /// Espèce dont le nom ressemble à [input], ou `null`.
  ///
  /// Ignore la casse et les accents ; tolère jusqu'à deux fautes de frappe sur
  /// les noms longs, une sur les noms moyens, aucune sur les noms courts.
  Species? findByName(String input) {
    final n = _normalize(input);
    if (n.isEmpty) return null;
    final exact = _normalized.indexOf(n);
    if (exact >= 0) return all[exact];
    final maxDistance = n.length >= 8 ? 2 : (n.length >= 5 ? 1 : 0);
    if (maxDistance == 0) return null;
    Species? best;
    var bestDistance = maxDistance + 1;
    for (var i = 0; i < all.length; i++) {
      final d = _distance(n, _normalized[i]);
      if (d < bestDistance) {
        best = all[i];
        bestDistance = d;
      }
    }
    return best;
  }

  /// Espèces proposées pour [input] : noms commençant par la saisie, puis la
  /// contenant, puis proches par la distance d'édition, au plus [max].
  List<Species> suggest(String input, {int max = 5}) {
    final n = _normalize(input);
    if (n.isEmpty) return const <Species>[];
    final starts = <int>[];
    final contains = <int>[];
    final close = <MapEntry<int, int>>[];
    for (var i = 0; i < all.length; i++) {
      final name = _normalized[i];
      if (name.startsWith(n)) {
        starts.add(i);
      } else if (name.contains(n)) {
        contains.add(i);
      } else {
        final d = _distance(n, name);
        if (d <= 2) close.add(MapEntry<int, int>(i, d));
      }
    }
    close.sort((a, b) => a.value.compareTo(b.value));
    final ordered = <int>[...starts, ...contains, ...close.map((e) => e.key)];
    return <Species>[for (final i in ordered.take(max)) all[i]];
  }

  /// Espèce désignée par [input], numéro du Pokédex ou nom, ou `null`.
  Species? lookup(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final dex = int.tryParse(text);
    if (dex != null) return findByDex(dex);
    return findByName(text);
  }
}

const Map<String, String> _fold = <String, String>{
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ÿ': 'y',
  'ñ': 'n',
  'œ': 'oe',
  'æ': 'ae',
  '♀': 'f',
  '♂': 'm',
};

String _normalize(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _fold[ch] ?? ch;
    for (final unit in mapped.codeUnits) {
      final isDigit = unit >= 0x30 && unit <= 0x39;
      final isLetter = unit >= 0x61 && unit <= 0x7a;
      if (isDigit || isLetter) buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

int _distance(String a, String b) {
  if (a == b) return 0;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var best = previous[j] + 1;
      if (current[j - 1] + 1 < best) best = current[j - 1] + 1;
      if (previous[j - 1] + cost < best) best = previous[j - 1] + cost;
      current[j] = best;
    }
    previous = current;
  }
  return previous[b.length];
}
