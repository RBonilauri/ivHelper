import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/app.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';

import '../support/fake_meta.dart';
import '../support/fake_update.dart';

SpeciesRepository _repository() => SpeciesRepository(const <Species>[
      Species(
        dex: 663,
        nameFr: 'Flambusard',
        base: BaseStats(176, 155, 186),
        types: <PokeType>[PokeType.fire, PokeType.flying],
        fastMoves: <String>['INCINERATE'],
        chargedMoves: <String>['BRAVE_BIRD'],
      ),
      Species(dex: 661, nameFr: 'Passerouge', base: BaseStats(95, 80, 128)),
    ]);

MoveBook _moves() => MoveBook(const <Move>[
      Move(
        id: 'INCINERATE',
        nameFr: 'Calcination',
        type: PokeType.fire,
        isFast: true,
      ),
      Move(
        id: 'BRAVE_BIRD',
        nameFr: 'Rapace',
        type: PokeType.flying,
        isFast: false,
      ),
    ]);

Future<void> _pumpApp(
  WidgetTester tester, {
  String? meta,
  int currentBuild = 0,
}) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    IvHelperApp(
      repository: _repository(),
      moves: _moves(),
      settings: SettingsController(MemorySettingsStore()),
      metaSource: FakeMetaSource(local: meta ?? fakeMetaJson()),
      updateSource: FakeUpdateSource(latest: releaseJson(5)),
      currentBuild: currentBuild,
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
    await tester.tap(find.text('Hyper'));
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
    expect(find.textContaining('sur 216'), findsOneWidget);
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

  testWidgets('le menu ouvre la table des types', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table des types'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('type-card-normal')),
      findsOneWidget,
    );
  });

  testWidgets('le team builder analyse un Pokémon choisi', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team builder'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('slot-0')),
        matching: find.byType(TextField),
      ),
      'Flambus',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flambusard').last);
    await tester.pumpAndSettle();
    expect(find.text('Roche ×2,56'), findsOneWidget);
    expect(find.text('Plante ×0,39'), findsOneWidget);
    expect(find.text('Bilan de l\'équipe'), findsOneWidget);
  });

  testWidgets('la méta propose d\'ajouter à l\'équipe et de voir les IV',
      (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Méta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('mis à jour le 20/11/2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('meta-1')));
    await tester.pumpAndSettle();
    expect(find.text('Pires adversaires'), findsOneWidget);
    expect(find.text('Altaria'), findsOneWidget);

    await tester.tap(find.text('Ajouter à mon équipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emplacement 1 · vide'));
    await tester.pumpAndSettle();
    expect(
      find.text('Flambusard ajouté à l\'emplacement 1'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voir le rang de mes IV'));
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('enregistrer avec ligue et options, filtrer, voir, supprimer',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('save-rank')),
      findsOneWidget,
    );
    expect(find.textContaining('Rang 21 ·'), findsOneWidget);
    await tester.tap(find.text('Shiny'));
    await tester.tap(find.text('XXL'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    expect(
      find.text('Flambusard 15/15/15 enregistré (Hyper, rang 21)'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    expect(find.text('1 Pokémon sur 1'), findsOneWidget);
    expect(find.text('Hyper · rang 21'), findsOneWidget);
    expect(find.text('XXL'), findsOneWidget);
    await tester.tap(find.text('Super'));
    await tester.pumpAndSettle();
    expect(find.text('0 Pokémon sur 1'), findsOneWidget);
    await tester.tap(find.text('Toutes'));
    await tester.tap(find.text('Top 50'));
    await tester.pumpAndSettle();
    expect(find.text('1 Pokémon sur 1'), findsOneWidget);
    await tester.tap(find.text('Top 10'));
    await tester.pumpAndSettle();
    expect(find.text('0 Pokémon sur 1'), findsOneWidget);
    await tester.tap(find.text('Tous'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Afficher en mosaïque'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Afficher en liste'), findsOneWidget);
    await tester.tap(find.text('Flambusard'));
    await tester.pumpAndSettle();
    expect(find.text('Hyper · rang 21'), findsOneWidget);
    expect(find.text('Shiny'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce Pokémon ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Hyper · rang 21'), findsOneWidget);
    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun Pokémon enregistré'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('un rang 1 porte le badge doré', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    expect(find.text('★ Rang 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('la fiche méta surligne les Pokémon possédés', (tester) async {
    await _pumpApp(
      tester,
      meta: fakeMetaJson(best: <String>['Florges', 'Flambusard (Obscur)']),
    );
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Méta'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('meta-1')),
        matching: find.textContaining('Dans ta collection · rang'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('meta-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('owned-Flambusard (Obscur)')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('owned-Florges')), findsNothing);
    expect(find.text('En jaune : tu l\'as dans ta collection'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('une nouvelle version s\'affiche et s\'installe', (tester) async {
    await _pumpApp(tester, currentBuild: 3);
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle version 1.0.5 disponible'), findsOneWidget);
    await tester.tap(find.text('Mettre à jour'));
    await tester.pumpAndSettle();
    expect(
      find.text('Confirme l\'installation dans la fenêtre d\'Android.'),
      findsOneWidget,
    );
  });

  testWidgets('une compilation locale ne cherche pas de mise à jour',
      (tester) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('update-banner')), findsNothing);
  });

  testWidgets('importer un Pokémon de la collection dans l\'équipe, une fois',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Costume'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team builder'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importer de ma collection').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flambusard').last);
    await tester.pumpAndSettle();
    expect(find.text('Importé de ta collection'), findsOneWidget);
    expect(find.text('Roche ×2,56'), findsOneWidget);

    await tester.ensureVisible(find.text('Importer de ma collection').at(1));
    await tester.tap(find.text('Importer de ma collection').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Déjà dans l\'équipe'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('la méta ne marque pas un Pokémon tagué dans une autre ligue',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Méta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dans ta collection'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
