import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/game_data.dart';

import '../support/fake_game_data.dart';

void main() {
  test('lit espèces et attaques datées', () {
    final data = GameData.parse(
      updated: '2026-11-27',
      speciesJson: speciesJson(),
      movesJson: movesJson(),
    );
    expect(data.updated, '2026-11-27');
    expect(data.species.all, hasLength(3));
    expect(data.species.findByName('Flambusard')!.base.atk, 176);
    expect(data.moves['INCINERATE']!.nameFr, 'Calcination');
    expect(data.isNewerThan('2026-11-26'), isTrue);
    expect(data.isNewerThan('2026-11-27'), isFalse);
  });

  test('données illisibles ou vides refusées', () {
    for (final (s, m) in <(String, String)>[
      ('pas du json', movesJson()),
      ('[]', movesJson()),
      (speciesJson(), '{}'),
      ('[{"dex":"x"}]', movesJson()),
    ]) {
      expect(
        () => GameData.parse(updated: '2026-11-27', speciesJson: s, movesJson: m),
        throwsFormatException,
      );
    }
  });

  test('version : date AAAA-MM-JJ, sinon refusée', () {
    expect(readDataVersion(versionJson('2026-11-27')), '2026-11-27');
    expect(() => readDataVersion('{"updated":"hier"}'), throwsFormatException);
    expect(() => readDataVersion('{}'), throwsFormatException);
  });

  test('cache : un seul texte, relu à l\'identique', () {
    final raw = encodeGameDataCache(
      updated: '2026-11-27',
      speciesJson: speciesJson(),
      movesJson: movesJson(),
    );
    final back = decodeGameDataCache(raw);
    expect(back.updated, '2026-11-27');
    expect(back.species, speciesJson());
    expect(back.moves, movesJson());
    expect(() => decodeGameDataCache('{"updated":1}'), throwsFormatException);
  });

  test('la version incluse dans l\'appli est lisible', () {
    final raw = File('assets/game_data_version.json').readAsStringSync();
    expect(readDataVersion(raw), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(isoDateFr('2026-11-25'), '25/11/2026');
  });
}
