import 'dart:math' as math;
import 'dart:typed_data';

import 'poke_type.dart';
import 'species_repository.dart';
import 'stats.dart';

/// Une ligne de texte lue à l'écran, avec sa boîte en pixels.
class OcrLine {
  /// Crée une ligne.
  const OcrLine(this.text, this.left, this.top, this.right, this.bottom);

  /// Texte reconnu.
  final String text;

  /// Bord gauche.
  final double left;

  /// Bord haut.
  final double top;

  /// Bord droit.
  final double right;

  /// Bord bas.
  final double bottom;

  /// Hauteur de la ligne.
  double get height => bottom - top;
}

/// Image en RGBA 8 bits par canal, ligne par ligne.
class RgbaImage {
  /// Crée une image de [width] × [height] pixels.
  RgbaImage(this.width, this.height, this.bytes)
      : assert(bytes.length >= width * height * 4, 'tampon trop petit');

  /// Largeur.
  final int width;

  /// Hauteur.
  final int height;

  /// Pixels RGBA.
  final Uint8List bytes;

  /// Classe du pixel (x, y) pour la lecture des barres.
  BarPixel classify(int x, int y) {
    final i = (y * width + x) * 4;
    final r = bytes[i];
    final g = bytes[i + 1];
    final b = bytes[i + 2];
    final mx = math.max(r, math.max(g, b));
    final mn = math.min(r, math.min(g, b));
    final sat = mx == 0 ? 0.0 : (mx - mn) / mx;
    if (sat > 0.30 && mx > 130) return BarPixel.filled;
    if (sat < 0.10 && mx >= 170 && mx < 240) return BarPixel.track;
    if (mx >= 240 && sat < 0.10) return BarPixel.background;
    return BarPixel.other;
  }
}

/// Nature d'un pixel dans la zone des barres d'évaluation.
enum BarPixel {
  /// Partie colorée (orange, ou rouge à 15).
  filled,

  /// Partie grise de la barre.
  track,

  /// Fond blanc.
  background,

  /// Autre chose.
  other,
}

/// Ce que le texte de l'écran apprend sur le Pokémon.
class ScreenText {
  /// Crée une lecture.
  const ScreenText({
    this.cp,
    this.hpMax,
    this.sentenceNames = const <String>[],
    this.candyWords = const <String>[],
    this.otherWords = const <String>[],
    this.types = const <PokeType>[],
    this.attackLabel,
    this.defenseLabel,
    this.hpLabel,
  });

  /// PC lus en haut de l'écran.
  final int? cp;

  /// PV maximum (« 21 / 21 PV »).
  final int? hpMax;

  /// Noms tirés de la phrase « Ce Nosferapti a été attrapé… » (espèce exacte).
  final List<String> sentenceNames;

  /// Mots de la ligne des bonbons (« BONBON(S) NOSFERAPTI »).
  final List<String> candyWords;

  /// Autres mots en capitales, candidats au nom d'espèce.
  final List<String> otherWords;

  /// Types lus (« POISON / VOL »).
  final List<PokeType> types;

  /// Étiquette « Attaque » de l'évaluation.
  final OcrLine? attackLabel;

  /// Étiquette « Défense » de l'évaluation.
  final OcrLine? defenseLabel;

  /// Étiquette « PV » de l'évaluation.
  final OcrLine? hpLabel;

  /// Vrai si les trois étiquettes des barres ont été trouvées.
  bool get hasAppraisal =>
      attackLabel != null && defenseLabel != null && hpLabel != null;
}

const Map<String, PokeType> _typeWords = <String, PokeType>{
  'normal': PokeType.normal,
  'feu': PokeType.fire,
  'eau': PokeType.water,
  'plante': PokeType.grass,
  'electrik': PokeType.electric,
  'glace': PokeType.ice,
  'combat': PokeType.fighting,
  'poison': PokeType.poison,
  'sol': PokeType.ground,
  'vol': PokeType.flying,
  'psy': PokeType.psychic,
  'insecte': PokeType.bug,
  'roche': PokeType.rock,
  'spectre': PokeType.ghost,
  'dragon': PokeType.dragon,
  'tenebres': PokeType.dark,
  'acier': PokeType.steel,
  'fee': PokeType.fairy,
};

const Set<String> _stopWords = <String>{
  'bonbon', 'bonbons', 'poids', 'taille', 'attaque', 'defense', 'evaluer',
  'puissance', 'evoluer', 'nouveau', 'nouvelle', 'transferer', 'attrape',
  'france', 'favori', 'charge', 'chargee', 'immediate', 'pokemon',
};

/// Analyse le texte lu sur la fiche d'un Pokémon dans Pokémon GO.
ScreenText parseScreenText(List<OcrLine> input) {
  final lines = <OcrLine>[...input]..sort((a, b) => a.top.compareTo(b.top));
  final sentence = <String>[];
  final sentencePattern = RegExp(
    r'\bCet?t?e?\s+(.+?)\s+a\s+(?:été|ete|éte|eté)',
    caseSensitive: false,
  );
  int? cp;
  double? cpTop;
  int? hpMax;
  final candy = <String>[];
  final others = <String>[];
  final types = <PokeType>[];
  OcrLine? attack;
  OcrLine? defense;
  final pvLabels = <OcrLine>[];

  final cpPattern = RegExp(r'^\s*[PC][CP]?\s*(\d{1,5})\s*$', caseSensitive: false);
  final hpPattern = RegExp(r'(\d{1,4})\s*/\s*(\d{1,4})\s*P\s*V', caseSensitive: false);

  for (final line in lines) {
    final text = line.text.trim();
    final norm = normalizeName(text);
    final cpMatch = cpPattern.firstMatch(text);
    if (cpMatch != null && (cpTop == null || line.top < cpTop)) {
      cp = int.parse(cpMatch.group(1)!);
      cpTop = line.top;
    }
    final sentenceMatch = sentencePattern.firstMatch(text);
    if (sentenceMatch != null) sentence.add(sentenceMatch.group(1)!);
    final hpMatch = hpPattern.firstMatch(text);
    if (hpMatch != null) hpMax = int.parse(hpMatch.group(2)!);
    if (norm == 'attaque') attack = line;
    if (norm == 'defense') defense = line;
    if (norm == 'pv') pvLabels.add(line);

    final words = RegExp(r"[A-Za-zÀ-ÿ'’]+")
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    for (final w in words) {
      final t = _typeWords[normalizeName(w)];
      if (t != null && w == w.toUpperCase() && !types.contains(t)) types.add(t);
    }
    final isCandy = norm.contains('bonbon') || norm.contains('onbon');
    for (final w in words) {
      final n = normalizeName(w);
      if (n.length < 5 || _stopWords.contains(n) || _typeWords.containsKey(n)) {
        continue;
      }
      if (n.contains('bonbon') || n.contains('onbon')) continue;
      if (isCandy) {
        candy.add(w);
      } else if (w == w.toUpperCase()) {
        others.add(w);
      }
    }
  }

  OcrLine? hpLabel;
  final d = defense;
  for (final l in pvLabels) {
    if (d != null && l.top <= d.top) continue;
    if (hpLabel == null || l.top < hpLabel.top) hpLabel = l;
  }

  return ScreenText(
    sentenceNames: sentence,
    cp: cp,
    hpMax: hpMax,
    candyWords: candy,
    otherWords: others,
    types: types,
    attackLabel: attack,
    defenseLabel: defense,
    hpLabel: hpLabel,
  );
}

/// Lit la valeur (0 à 15) de la barre d'évaluation sous [label].
///
/// Cherche, sous l'étiquette, la ligne de pixels où la barre (partie colorée
/// et partie grise) est la plus longue, puis mesure jusqu'où va la couleur.
int? readBar(RgbaImage image, OcrLine label) {
  final h = math.max(label.height, 8.0);
  final y0 = label.bottom.round();
  final y1 = math.min(image.height - 1, (label.bottom + 2.5 * h).round());
  final x0 = math.max(0, (label.left - h).round());
  final x1 = math.min(image.width - 1, (label.left + 20 * h).round());
  final maxGap = math.max(3, (0.45 * h).round());
  var bestLen = 0;
  int? bestValue;
  for (var y = y0; y <= y1; y++) {
    var x = x0;
    while (x <= x1) {
      final c = image.classify(x, y);
      if (c != BarPixel.filled && c != BarPixel.track) {
        x++;
        continue;
      }
      final start = x;
      var last = x;
      var lastFilled = -1;
      var gap = 0;
      while (x <= x1) {
        final k = image.classify(x, y);
        if (k == BarPixel.filled || k == BarPixel.track) {
          last = x;
          gap = 0;
          if (k == BarPixel.filled) lastFilled = x;
        } else {
          gap++;
          if (gap > maxGap) break;
        }
        x++;
      }
      final len = last - start + 1;
      if (len > bestLen) {
        bestLen = len;
        bestValue = lastFilled < 0
            ? 0
            : ((lastFilled - start + 1) / len * 15).round().clamp(0, 15);
      }
    }
  }
  return bestLen >= 4 * h ? bestValue : null;
}

/// Lit les trois barres d'évaluation, ou `null` si une barre manque.
Iv? readAppraisal(RgbaImage image, ScreenText text) {
  final a = text.attackLabel;
  final d = text.defenseLabel;
  final s = text.hpLabel;
  if (a == null || d == null || s == null) return null;
  final atk = readBar(image, a);
  final def = readBar(image, d);
  final sta = readBar(image, s);
  if (atk == null || def == null || sta == null) return null;
  return Iv(atk, def, sta);
}

/// Pokémon reconnu à l'écran.
class ScanResult {
  /// Crée un résultat.
  const ScanResult({
    required this.species,
    required this.family,
    required this.iv,
    required this.text,
    this.level,
  });

  /// Espèce au stade affiché, ou `null` si inconnue.
  final Species? species;

  /// Famille d'évolution (vide si l'espèce est inconnue).
  final List<Species> family;

  /// IV lus, ou `null` sans évaluation à l'écran.
  final Iv? iv;

  /// Texte analysé.
  final ScreenText text;

  /// Niveau déduit des PC et PV, ou `null`.
  final double? level;
}

/// Niveau auquel [species] avec [iv] a exactement [cp] PC et [hpMax] PV, ou
/// `null`.
double? matchingLevel(Species species, Iv iv, int cp, int hpMax) {
  for (var i = 0; i <= 100; i++) {
    final level = 1 + i / 2;
    if (computeCp(species.base, iv, level) == cp &&
        computeHp(species.base, iv, level) == hpMax) {
      return level;
    }
  }
  return null;
}

/// Reconnaît l'espèce : la famille vient du nom sur les bonbons (ou d'un autre
/// mot en capitales), le stade des PC et PV avec les IV lus.
ScanResult identify(SpeciesRepository repo, ScreenText text, Iv? iv) {
  Species? named;
  for (final w in <String>[
    ...text.sentenceNames,
    ...text.candyWords,
    ...text.otherWords,
  ]) {
    named = repo.findByName(w);
    if (named != null) break;
  }
  final cp = text.cp;
  final hp = text.hpMax;
  if (named != null) {
    final family = repo.familyOf(named);
    if (iv != null && cp != null && hp != null) {
      for (final s in family) {
        final level = matchingLevel(s, iv, cp, hp);
        if (level != null) {
          return ScanResult(
            species: s,
            family: family,
            iv: iv,
            text: text,
            level: level,
          );
        }
      }
    }
    return ScanResult(species: family.first, family: family, iv: iv, text: text);
  }
  if (iv != null && cp != null && hp != null) {
    for (final s in repo.all) {
      if (text.types.isNotEmpty &&
          !(s.types.length == text.types.length &&
              s.types.every(text.types.contains))) {
        continue;
      }
      final level = matchingLevel(s, iv, cp, hp);
      if (level != null) {
        return ScanResult(
          species: s,
          family: repo.familyOf(s),
          iv: iv,
          text: text,
          level: level,
        );
      }
    }
  }
  return ScanResult(
    species: null,
    family: const <Species>[],
    iv: iv,
    text: text,
  );
}
