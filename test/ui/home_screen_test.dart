import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/app.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';

SpeciesRepository _repository() => SpeciesRepository(const <Species>[
      Species(dex: 663, nameFr: 'Flambusard', base: BaseStats(176, 155, 186)),
      Species(dex: 661, nameFr: 'Passerouge', base: BaseStats(95, 80, 128)),
    ]);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    IvHelperApp(
      repository: _repository(),
      settings: SettingsController(MemorySettingsStore()),
    ),
  );
}

void main() {
  testWidgets('l\'écran d\'accueil invite à saisir un Pokémon', (tester) async {
    await _pumpApp(tester);
    expect(find.text('ivHelper'), findsOneWidget);
    expect(find.text('Rang 2 246'), findsNothing);
  });

  testWidgets('saisir un nom affiche les résultats Super et Hyper',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
    expect(find.text('Rang 2 246'), findsOneWidget);
  });

  testWidgets('saisir un numéro de Pokédex fonctionne aussi', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), '663');
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
  });

  testWidgets('un nom inconnu affiche un message sans résultat',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Zorglub');
    await tester.pumpAndSettle();
    expect(find.text('Espèce inconnue'), findsOneWidget);
    expect(find.textContaining('Rang'), findsNothing);
  });

  testWidgets('baisser l\'IV d\'attaque change le rang', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Diminuer Atk'));
    await tester.pumpAndSettle();
    expect(find.text('Rang 2 246'), findsNothing);
  });

  testWidgets('le niveau max 50 place le 15/15/15 au rang 1 en hyper',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Max 50'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyper · 2500'));
    await tester.pumpAndSettle();
    expect(find.text('Rang 1'), findsOneWidget);
  });

  testWidgets('Min 10/10/10 relève les IV et restreint le classement',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Min 10/10/10'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sur 1 331'), findsOneWidget);
  });

  testWidgets('le bouton Paramètres ouvre la barre latérale', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Mode d\'affichage'), findsOneWidget);
    expect(find.textContaining('Taille de police'), findsOneWidget);
  });

  testWidgets('choisir Nuit passe l\'application en mode sombre',
      (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuit'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
