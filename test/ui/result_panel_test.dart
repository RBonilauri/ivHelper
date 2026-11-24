import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/rank_service.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/ui/result_panel.dart';

const _flambusard = Species(
  dex: 663,
  nameFr: 'Flambusard',
  base: BaseStats(176, 155, 186),
);

Future<void> _pumpPanel(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final result = rankIv(_flambusard.base, const Iv(15, 15, 15));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResultPanel(species: _flambusard, result: result),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('le volet Super s\'affiche en premier avec le rang 2 246',
      (tester) async {
    await _pumpPanel(tester);
    expect(find.text('Super · 1500'), findsOneWidget);
    expect(find.text('Hyper · 2500'), findsOneWidget);
    expect(find.text('Rang 2 246'), findsOneWidget);
    expect(find.textContaining('sur 4 096'), findsOneWidget);
  });

  testWidgets('le volet Hyper affiche le rang 21 et la ligne mise en avant',
      (tester) async {
    await _pumpPanel(tester);
    await tester.tap(find.text('Hyper · 2500'));
    await tester.pumpAndSettle();
    expect(find.text('Rang 21'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('mine-row')), findsOneWidget);
    expect(find.text('13/15/15'), findsOneWidget);
  });

  testWidgets('le tableau montre la ligne de l\'utilisateur puis le top 10',
      (tester) async {
    await _pumpPanel(tester);
    await tester.tap(find.text('Hyper · 2500'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('rank-row')), findsNWidgets(10));
  });

  testWidgets('toucher une ligne déplie ses stats réelles', (tester) async {
    await _pumpPanel(tester);
    await tester.tap(find.text('Hyper · 2500'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stat globale'), findsNothing);
    await tester.tap(find.text('13/15/15'));
    await tester.pumpAndSettle();
    expect(
      find.text('Atk 159,7 · Déf 143,7 · PV 169 · '
          'Stat globale 3 879 888'),
      findsOneWidget,
    );
  });

  testWidgets('l\'interrupteur Détails déplie toutes les lignes',
      (tester) async {
    await _pumpPanel(tester);
    await tester.tap(find.text('Hyper · 2500'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stat globale'), findsNWidgets(11));
  });
}
