import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/collection.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/power_up.dart';
import 'package:ivhelper/core/rank_service.dart';
import 'package:ivhelper/core/screen_reading.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/overlay/overlay_app.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/ui/format.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_meta.dart';
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
    // Meilleur ami décoché par défaut (niveau 50).
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Meilleur ami (niveau 51)'),
          )
          .value,
      isFalse,
    );
    expect(find.textContaining('Touche une case'), findsNothing);
    expect(find.byKey(const ValueKey<String>('info-family-table')), findsOneWidget);

    // Sous « Enregistrer » : copier le surnom PVP#rang de la case choisie.
    // La copie passe par la fenêtre (plugin natif) et non par Clipboard,
    // sans effet dans le moteur de la pastille.
    final rank = rankIv(_crobat.base, const Iv(0, 13, 10), maxLevel: 50).ultra.mine.rank;
    final copy = find.byKey(const ValueKey<String>('copy-nickname'));
    expect(
      tester.getTopLeft(copy).dy,
      greaterThan(tester.getTopLeft(find.text('Enregistrer Nostenfer (Hyper)')).dy),
    );
    expect(find.text('Copier PVP#$rank'), findsOneWidget);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(window.copied, <String>['PVP#$rank']);
    expect(find.text('PVP#$rank copié : colle-le comme surnom dans le jeu.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
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

  Future<FakeOverlayWindow> openPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SpeciesRepository(const <Species>[_zubat, _golbat, _crobat]);
    final window = FakeOverlayWindow();
    await tester.pumpWidget(
      OverlayApp(
        repository: repo,
        moves: MoveBook(const <Move>[]),
        settings: SettingsController(MemorySettingsStore()),
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
    expect(find.byTooltip('Arrêter la superposition'), findsOneWidget);
    return window;
  }

  testWidgets('arrêter depuis le panneau remet la pastille pour la relance',
      (tester) async {
    final window = await openPanel(tester);

    await tester.tap(find.byTooltip('Arrêter la superposition'));
    await tester.pumpAndSettle();

    // Le moteur de la pastille survit à la fermeture : à la relance, il doit
    // montrer la pastille, pas le panneau dans une fenêtre de 64 dp.
    expect(window.calls.last, 'stop');
    expect(find.byKey(const ValueKey<String>('overlay-bubble')), findsOneWidget);
    expect(find.byTooltip('Arrêter la superposition'), findsNothing);
  });

  testWidgets('un panneau dans une fenêtre de pastille redevient la pastille',
      (tester) async {
    final window = await openPanel(tester);

    // Fenêtre recréée à la taille de la pastille (relance depuis l'app).
    tester.view.physicalSize = const Size(64, 64);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('overlay-bubble')), findsOneWidget);
    expect(find.byTooltip('Arrêter la superposition'), findsNothing);

    // Toucher la pastille relit l'écran et rouvre le panneau.
    await tester.tap(find.byKey(const ValueKey<String>('overlay-bubble')));
    await tester.pumpAndSettle();
    expect(window.calls.where((c) => c == 'panel'), hasLength(2));
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

  testWidgets('rang dans la méta et coût pour monter au niveau de la ligue',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SpeciesRepository(const <Species>[_zubat, _golbat, _crobat]);
    await tester.pumpWidget(
      OverlayApp(
        repository: repo,
        moves: MoveBook(const <Move>[]),
        settings: SettingsController(MemorySettingsStore()),
        window: FakeOverlayWindow(),
        meta: MetaSnapshot.fromJson(
          fakeMetaJson(name: 'Nostenfer', species: 'Nostenfer'),
        ),
        scanner: FakeScreenScanner(
          ScanResult(
            species: _zubat,
            family: repo.familyOf(_zubat),
            iv: const Iv(0, 13, 10),
            text: const ScreenText(cp: 24, hpMax: 21, lucky: true),
            level: 2,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('overlay-bubble')));
    await tester.pumpAndSettle();

    // Nostenfer en Super : premier de la (fausse) méta.
    await tester.tap(find.byKey(const ValueKey<String>('cell-Nostenfer-great')));
    await tester.pumpAndSettle();
    expect(find.text('Méta Super : n° 1'), findsOneWidget);

    // Chanceux lu à l'écran : coché d'office, poussière divisée par deux.
    final lucky = find.widgetWithText(FilterChip, 'Chanceux');
    expect(tester.widget<FilterChip>(lucky).selected, isTrue);
    final target = rankIv(_crobat.base, const Iv(0, 13, 10), maxLevel: 50)
        .great
        .mine
        .level;
    String text(String key) =>
        tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;
    final luckyCost = powerUpCost(2, target, lucky: true)!;
    expect(text('cost-stardust'), formatGrouped(luckyCost.stardust));
    expect(text('cost-candy'), formatGrouped(luckyCost.candy));

    await tester.tap(lucky);
    await tester.pumpAndSettle();
    final normal = powerUpCost(2, target)!;
    expect(text('cost-stardust'), formatGrouped(normal.stardust));
    expect(normal.stardust, luckyCost.stardust * 2);

    await tester.tap(find.widgetWithText(FilterChip, 'Obscur'));
    await tester.pumpAndSettle();
    final shadow = powerUpCost(2, target, shadow: ShadowState.shadow)!;
    expect(text('cost-stardust'), formatGrouped(shadow.stardust));
    expect(text('cost-candy'), formatGrouped(shadow.candy));

    // Ligue Mini : pas de méta.
    await tester.tap(find.byKey(const ValueKey<String>('cell-Nosferapti-little')));
    await tester.pumpAndSettle();
    expect(find.text('Pas de méta en ligue Mini'), findsOneWidget);
  });

  testWidgets('la pastille montre les coupes de la ligue choisie',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SpeciesRepository(const <Species>[_zubat, _golbat, _crobat]);
    await tester.pumpWidget(
      OverlayApp(
        repository: repo,
        moves: MoveBook(const <Move>[]),
        settings: SettingsController(MemorySettingsStore()),
        window: FakeOverlayWindow(),
        meta: MetaSnapshot.fromJson(
          fakeMetaJson(
            name: 'Nostenfer',
            species: 'Nostenfer',
            cups: <Object?>[
              fakeCupJson(
                entries: <Map<String, Object?>>[
                  fakeMetaEntry(name: 'Nostenfer', species: 'Nostenfer'),
                ],
                eligible: <String>['Nostenfer'],
              ),
            ],
          ),
        ),
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
    await tester.tap(find.byKey(const ValueKey<String>('cell-Nostenfer-great')));
    await tester.pumpAndSettle();
    String text(String key) =>
        tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;
    expect(text('cups-rank'), 'Coupes : Battle Frontier (Spectral) n° 1');
    // Forme obscure : pas admise dans cette coupe.
    await tester.tap(find.widgetWithText(FilterChip, 'Obscur'));
    await tester.pumpAndSettle();
    expect(text('cups-rank'), 'Coupes Super : aucune ne l\'accepte');
  });
}
