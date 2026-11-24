import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/screen_reading.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/overlay/overlay_app.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_overlay.dart';

const _types = <PokeType>[PokeType.poison, PokeType.flying];
const _zubat = Species(
  dex: 41,
  nameFr: 'Nosferapti',
  base: BaseStats(83, 73, 120),
  types: _types,
  familyId: 'FAMILY_ZUBAT',
);
const _golbat = Species(
  dex: 42,
  nameFr: 'Nosferalto',
  base: BaseStats(161, 150, 181),
  types: _types,
  familyId: 'FAMILY_ZUBAT',
  stage: 1,
);
const _crobat = Species(
  dex: 169,
  nameFr: 'Nostenfer',
  base: BaseStats(194, 178, 198),
  types: _types,
  familyId: 'FAMILY_ZUBAT',
  stage: 2,
);

void main() {
  testWidgets('la pastille lit l\'écran, montre les stades et enregistre',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SpeciesRepository(const <Species>[_zubat, _golbat, _crobat]);
    final store = MemorySettingsStore();
    final window = FakeOverlayWindow();
    await tester.pumpWidget(
      OverlayApp(
        repository: repo,
        moves: MoveBook(const <Move>[]),
        settings: SettingsController(store),
        window: window,
        scanner: FakeScreenScanner(
          ScanResult(
            species: _zubat,
            family: repo.familyOf(_zubat),
            iv: const Iv(0, 13, 10),
            text: const ScreenText(cp: 24, hpMax: 21),
            level: 2,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('overlay-bubble')));
    await tester.pumpAndSettle();
    expect(window.calls, contains('panel'));
    expect(find.text('Nosferapti · PC 24 · PV 21 · niveau 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cell-Nostenfer-great')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('iv-value-Déf'))).data,
      '13',
    );

    await tester.tap(find.byKey(const ValueKey<String>('cell-Nostenfer-ultra')));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer Nostenfer (Hyper)'), findsOneWidget);
    await tester.tap(find.text('Enregistrer Nostenfer (Hyper)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    expect(await store.readCollection(), contains('Nostenfer'));
    expect(await store.readCollection(), contains('"league":"ultra"'));

    await tester.tap(find.byTooltip('Réduire'));
    await tester.pumpAndSettle();
    expect(window.calls.last, 'bubble');
    expect(find.byKey(const ValueKey<String>('overlay-bubble')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('sans barres, la pastille le dit et laisse régler les IV',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SpeciesRepository(const <Species>[_zubat, _golbat, _crobat]);
    await tester.pumpWidget(
      OverlayApp(
        repository: repo,
        moves: MoveBook(const <Move>[]),
        settings: SettingsController(MemorySettingsStore()),
        window: FakeOverlayWindow(),
        scanner: FakeScreenScanner(
          ScanResult(
            species: _zubat,
            family: repo.familyOf(_zubat),
            iv: null,
            text: const ScreenText(cp: 24, hpMax: 21),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('overlay-bubble')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('scan-error')), findsOneWidget);
    expect(find.textContaining('Barres non trouvées'), findsOneWidget);
  });
}
