import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/history_controller.dart';
import 'package:ivhelper/ui/iv_bar.dart';

void main() {
  test('une recherche par espèce, la plus récente en tête, 8 au plus', () {
    final h = HistoryController(MemorySettingsStore())
      ..record('Flambusard', const Iv(15, 15, 15))
      ..record('Altaria', const Iv(0, 15, 15))
      ..record('Flambusard', const Iv(13, 15, 15));
    expect(h.items.map((e) => e.speciesName), <String>['Flambusard', 'Altaria']);
    expect(h.items.first.iv, const Iv(13, 15, 15));
    for (var i = 0; i < 10; i++) {
      h.record('Espèce $i', const Iv(1, 1, 1));
    }
    expect(h.items.length, HistoryController.maxItems);
    h.clear();
    expect(h.items, isEmpty);
  });

  test('l\'historique est enregistré puis rechargé', () async {
    final store = MemorySettingsStore();
    HistoryController(store).record('Altaria', const Iv(0, 15, 14));
    final again = HistoryController(store);
    await again.load();
    expect(again.items.single.speciesName, 'Altaria');
    expect(again.items.single.iv, const Iv(0, 15, 14));
  });

  test('parseIvText lit plusieurs écritures et refuse le reste', () {
    expect(parseIvText('15/14/13'), <int>[15, 14, 13]);
    expect(parseIvText('0 15 15'), <int>[0, 15, 15]);
    expect(parseIvText('151413'), <int>[15, 14, 13]);
    expect(parseIvText('001510'), <int>[0, 15, 10]);
    expect(parseIvText('16/1/1'), isNull);
    expect(parseIvText('15/14'), isNull);
    expect(parseIvText(''), isNull);
  });
}
