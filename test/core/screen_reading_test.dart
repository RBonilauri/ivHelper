import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/screen_reading.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';

/// Lignes lues sur la fiche d'un Nosferapti surnommé « PVP », en évaluation
/// (une partie de la ligne des bonbons est cachée par la cheffe d'équipe).
const List<OcrLine> _nosferaptiLines = <OcrLine>[
  OcrLine('PC24', 450, 140, 640, 220),
  OcrLine('PVP', 510, 1030, 660, 1090),
  OcrLine('21 / 21 PV', 505, 1170, 655, 1200),
  OcrLine('4,64kg', 160, 1345, 305, 1390),
  OcrLine('POIDS', 180, 1410, 285, 1440),
  OcrLine('POISON / VO', 465, 1410, 700, 1445),
  OcrLine('0,68m', 865, 1345, 1000, 1390),
  OcrLine('TAILLE', 880, 1410, 985, 1440),
  OcrLine('ONBON(S) L', 895, 1665, 1075, 1700),
  OcrLine('OSFERAPTI', 880, 1700, 1035, 1735),
  OcrLine('Attaque', 140, 1880, 275, 1915),
  OcrLine('Défense', 138, 1990, 275, 2025),
  OcrLine('PV', 138, 2095, 180, 2130),
  OcrLine('Ce Nosferapti a été attrapé le 28/10/2026', 80, 2320, 1060, 2370),
];

/// Image blanche avec trois barres d'évaluation sous des étiquettes de 30 px.
RgbaImage _appraisalImage(List<int> values) {
  const width = 400;
  const height = 400;
  final bytes = Uint8List(width * height * 4)..fillRange(0, width * height * 4, 255);
  void put(int x, int y, int r, int g, int b) {
    final i = (y * width + x) * 4;
    bytes[i] = r;
    bytes[i + 1] = g;
    bytes[i + 2] = b;
    bytes[i + 3] = 255;
  }

  for (var bar = 0; bar < 3; bar++) {
    final top = 140 + bar * 100;
    final filledEnd = 20 + (300 * values[bar] / 15).round();
    for (var y = top; y < top + 14; y++) {
      for (var x = 20; x < 320; x++) {
        if ((x >= 119 && x < 122) || (x >= 219 && x < 222)) continue;
        if (x < filledEnd) {
          final red = values[bar] == 15;
          put(x, y, red ? 232 : 232, red ? 110 : 164, red ? 110 : 73);
        } else {
          put(x, y, 226, 226, 224);
        }
      }
    }
  }
  return RgbaImage(width, height, bytes);
}

ScreenText _labels() => const ScreenText(
      attackLabel: OcrLine('Attaque', 20, 100, 120, 130),
      defenseLabel: OcrLine('Défense', 20, 200, 120, 230),
      hpLabel: OcrLine('PV', 20, 300, 60, 330),
    );

void main() {
  test('le texte donne PC, PV, nom, types et étiquettes des barres', () {
    final t = parseScreenText(_nosferaptiLines);
    expect(t.cp, 24);
    expect(t.hpMax, 21);
    expect(t.sentenceNames, <String>['Nosferapti']);
    expect(t.otherWords, contains('OSFERAPTI'));
    expect(t.types, <PokeType>[PokeType.poison]);
    expect(t.hasAppraisal, isTrue);
    expect(t.hpLabel!.top, 2095);
  });

  test('le « PV » de « 21 / 21 PV » n\'est pas pris pour une étiquette', () {
    final t = parseScreenText(const <OcrLine>[
      OcrLine('PV', 500, 1170, 540, 1200),
      OcrLine('Défense', 138, 1990, 275, 2025),
      OcrLine('PV', 138, 2095, 180, 2130),
    ]);
    expect(t.hpLabel!.top, 2095);
  });

  test('les barres se lisent à l\'unité, de 0 à 15', () {
    for (final values in <List<int>>[
      <int>[0, 13, 10],
      <int>[15, 15, 15],
      <int>[1, 7, 14],
      <int>[5, 6, 11],
    ]) {
      final iv = readAppraisal(_appraisalImage(values), _labels());
      expect(iv, Iv(values[0], values[1], values[2]), reason: '$values');
    }
  });

  test('sans barre sous l\'étiquette, la lecture échoue', () {
    final empty = RgbaImage(
      200,
      200,
      Uint8List(200 * 200 * 4)..fillRange(0, 200 * 200 * 4, 255),
    );
    expect(readBar(empty, const OcrLine('Attaque', 20, 20, 120, 50)), isNull);
  });

  group('avec les vraies espèces', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late SpeciesRepository repo;
    setUpAll(() async => repo = await SpeciesRepository.load());

    test('Nosferapti 0/13/10 à 24 PC et 21 PV : niveau 2, famille de 3', () {
      final t = parseScreenText(_nosferaptiLines);
      final r = identify(repo, t, const Iv(0, 13, 10));
      expect(r.species?.nameFr, 'Nosferapti');
      expect(r.level, 2);
      expect(
        r.family.map((s) => s.nameFr),
        <String>['Nosferapti', 'Nosferalto', 'Nostenfer'],
      );
    });

    test('sans la phrase, le nom à moitié caché suffit', () {
      final t = parseScreenText(<OcrLine>[
        for (final l in _nosferaptiLines)
          if (!l.text.startsWith('Ce ')) l,
      ]);
      expect(identify(repo, t, const Iv(0, 13, 10)).species?.nameFr, 'Nosferapti');
    });

    test('sans nom lisible, PC, PV, types et IV retrouvent l\'espèce', () {
      final r = identify(
        repo,
        const ScreenText(
          cp: 24,
          hpMax: 21,
          types: <PokeType>[PokeType.poison, PokeType.flying],
        ),
        const Iv(0, 13, 10),
      );
      expect(r.species?.nameFr, 'Nosferapti');
    });

    test('le stade vient des PC et PV quand la famille est connue', () {
      final nostenfer = repo.findByName('Nostenfer')!;
      const iv = Iv(4, 15, 13);
      final cp = computeCp(nostenfer.base, iv, 20);
      final hp = computeHp(nostenfer.base, iv, 20);
      final r = identify(
        repo,
        ScreenText(cp: cp, hpMax: hp, candyWords: const <String>['NOSFERAPTI']),
        iv,
      );
      expect(r.species?.nameFr, 'Nostenfer');
      expect(r.level, 20);
    });
  });
}
