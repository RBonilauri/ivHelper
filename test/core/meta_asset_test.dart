import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/species_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la méta incluse couvre Super, Hyper et Master, rangs sans trou',
      () async {
    final data = MetaData.fromJson(
      await rootBundle.loadString('assets/meta.json'),
    );
    for (final league in MetaLeague.values) {
      final entries = data.leagues[league]!;
      expect(entries, isNotEmpty, reason: league.label);
      expect(entries.length, lessThanOrEqualTo(100));
      expect(
        entries.map((e) => e.rank),
        List<int>.generate(entries.length, (i) => i + 1),
      );
    }
  });

  test('chaque espèce citée par la méta existe dans species.json', () async {
    final data = MetaData.fromJson(
      await rootBundle.loadString('assets/meta.json'),
    );
    final repo = await SpeciesRepository.load();
    final names = <String>{for (final s in repo.all) s.nameFr};
    for (final entries in data.leagues.values) {
      for (final e in entries) {
        final species = e.species;
        if (species != null) expect(names, contains(species), reason: e.name);
      }
    }
  });
}
