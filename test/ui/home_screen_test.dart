import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/app.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';
import 'package:ivhelper/core/stats.dart';
import 'package:ivhelper/settings/settings_controller.dart';

import '../support/fake_account_files.dart';
import '../support/fake_meta.dart';
import '../support/fake_overlay.dart';
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
        power: 20,
      ),
      Move(
        id: 'BRAVE_BIRD',
        nameFr: 'Rapace',
        type: PokeType.flying,
        isFast: false,
        power: 130,
        energy: 55,
        effects: <StatChange>[
          StatChange(target: StatTarget.self, defense: -3),
        ],
      ),
    ]);

Future<void> _pumpApp(
  WidgetTester tester, {
  String? meta,
  int currentBuild = 0,
  FakeAccountFiles? files,
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
      overlayLauncher: FakeOverlayLauncher(),
      accountFiles: files ?? FakeAccountFiles(),
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
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
    expect(find.text('Rang 2 246'), findsOneWidget);
  });

  testWidgets('saisir un numéro de Pokédex fonctionne aussi', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, '663');
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
  });

  testWidgets('un nom inconnu affiche un message sans résultat',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Zorglub');
    await tester.pumpAndSettle();
    expect(find.text('Espèce inconnue'), findsOneWidget);
    expect(find.textContaining('Rang'), findsNothing);
  });

  testWidgets('baisser l\'IV d\'attaque change le rang', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Diminuer Atk'));
    await tester.pumpAndSettle();
    expect(find.text('Rang 2 246'), findsNothing);
  });

  testWidgets('par défaut, niveau max 50 et tous les IV : 15/15/15 rang 1 en hyper',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    final level = tester.widget<SegmentedButton<double>>(
      find.byType(SegmentedButton<double>),
    );
    expect(level.selected, <double>{50});
    final floor = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(floor.selected, <int>{0});
    await tester.tap(find.text('Hyper'));
    await tester.pumpAndSettle();
    expect(find.text('Rang 1'), findsOneWidget);
  });

  testWidgets('Min 10/10/10 relève les IV et restreint le classement',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
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
      find.byKey(const ValueKey<String>('type-pick-normal')),
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
    // Rubriques du bilan ouvertes par défaut.
    await tester.scrollUntilVisible(
      find.text('Aucune attaque choisie'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Aucune attaque choisie'), findsOneWidget);
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
    expect(find.text('Ta défense \u22123'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('charge-bars-BRAVE_BIRD')),
      findsOneWidget,
    );

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
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Max 51 (ami)'));
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
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
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
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
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
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
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
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
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

  testWidgets('le bandeau « Voir » disparaît après 5 secondes', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('le bilan d\'équipe montre la couverture offensive',
      (tester) async {
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
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('slot-0')),
            matching: find.text('Aucune'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcination').last);
    await tester.pumpAndSettle();
    expect(find.text('Super efficace contre (4/18)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('stat-coverage')),
        matching: find.text('4/18'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('le menu d\'enregistrement met les attaques méta en gras, sans ★',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('meta-moves')), findsNothing);
    expect(find.text('Utiliser'), findsNothing);
    // Flambusard n'est classé qu'en Super dans la méta de test : en Master,
    // ses attaques de la méta Super restent en gras.
    await tester.tap(find.text('Master').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aucune').first);
    await tester.pumpAndSettle();
    final calcination = find.text('Calcination').last;
    expect(
      tester.widget<Text>(calcination).style?.fontWeight,
      FontWeight.w800,
    );
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('saisie des IV : barre à toucher et saisie rapide',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey<String>('iv-bar-Atk'));
    await tester.tapAt(tester.getCenter(bar));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('iv-value-Atk'))).data,
      '8',
    );
    await tester.tap(find.text('Max 51 (ami)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('quick-iv')),
      '13/15/15',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyper'));
    await tester.pumpAndSettle();
    expect(find.text('Rang 1'), findsOneWidget);
  });

  testWidgets('sans recherche, les dernières recherches sont proposées',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Diminuer PV'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    expect(find.text('Dernières recherches'), findsOneWidget);
    await tester.tap(find.text('Flambusard · 15/15/14'));
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('iv-value-PV'))).data,
      '14',
    );
  });

  testWidgets('collection : filtre de type en un appui', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
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
    expect(find.byKey(const ValueKey<String>('type-filter-fire')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('type-filter-water')), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('type-filter-flying')));
    await tester.pumpAndSettle();
    expect(find.text('Types · 1 choisi'), findsOneWidget);
    expect(find.text('1 Pokémon sur 1'), findsOneWidget);
    await tester.tap(find.text('Tous les types'));
    await tester.pumpAndSettle();
    expect(find.text('Types (touche pour filtrer)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('le menu lance la superposition', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Superposition'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pastille lancée'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('la croix efface la recherche du Pokémon', (tester) async {
    await _pumpApp(tester);
    expect(find.byTooltip('Effacer'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsOneWidget);
    await tester.tap(find.byTooltip('Effacer').first);
    await tester.pumpAndSettle();
    expect(find.text('Flambusard · n° 663'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '',
    );
    expect(find.byTooltip('Effacer'), findsNothing);
  });

  testWidgets('la superposition est en bas des entrées du menu', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    final overlay = tester.getTopLeft(find.text('Superposition')).dy;
    for (final other in <String>[
      'Ma collection',
      'Méta',
      'Team builder',
      'Table des types',
    ]) {
      expect(overlay, greaterThan(tester.getTopLeft(find.text(other)).dy));
    }
  });

  testWidgets('la fiche de la collection range les attaques par catégorie',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aucune').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcination').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aucune').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rapace').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flambusard').first);
    await tester.pumpAndSettle();

    expect(find.text('Immédiate'), findsOneWidget);
    expect(find.text('Chargée(s)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Immédiate')).dy,
      lessThan(tester.getTopLeft(find.text('Calcination')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Chargée(s)')).dy,
      lessThan(tester.getTopLeft(find.text('Rapace')).dy),
    );
    expect(
      tester.widget<Text>(find.text('Calcination')).style?.fontWeight,
      FontWeight.w800,
    );
    expect(find.text('20'), findsOneWidget);
    expect(find.text('130'), findsOneWidget);
    expect(find.textContaining('puissance'), findsNothing);
    // Barres d'énergie de la couleur du type et effet sur les stats.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('charge-bars-BRAVE_BIRD')),
        matching: find.byKey(const ValueKey<String>('charge-bar')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('charge-bars-INCINERATE')),
      findsNothing,
    );
    expect(find.text('Ta défense \u22123'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('méta : filtres de type, de type d\'attaque et possédés',
      (tester) async {
    await _pumpApp(tester, meta: fakeMetaJson(withAltaria: true));
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Méta'));
    await tester.pumpAndSettle();

    final flambusard = find.byKey(const ValueKey<String>('meta-1'));
    final altaria = find.byKey(const ValueKey<String>('meta-2'));
    expect(flambusard, findsOneWidget);
    expect(altaria, findsOneWidget);

    // Possédés dans la ligue affichée.
    await tester.tap(find.byKey(const ValueKey<String>('meta-owned')));
    await tester.pumpAndSettle();
    expect(flambusard, findsOneWidget);
    expect(altaria, findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('meta-owned')));
    await tester.pumpAndSettle();

    // Menu déroulant des filtres : type du Pokémon.
    // Types en ligne, comme dans la collection : pas de volet à ouvrir.
    expect(find.text('Filtres'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('meta-type-dragon')));
    await tester.pumpAndSettle();
    expect(flambusard, findsNothing);
    expect(altaria, findsOneWidget);
    expect(find.text('Types du Pokémon · 1 choisi'), findsOneWidget);
    // Plusieurs types cochés : un seul suffit.
    await tester.tap(find.byKey(const ValueKey<String>('meta-type-fire')));
    await tester.pumpAndSettle();
    expect(flambusard, findsOneWidget);
    expect(altaria, findsOneWidget);
    expect(find.text('Types du Pokémon · 2 choisis'), findsOneWidget);
    await tester.tap(find.text('Tous les types').first);
    await tester.pumpAndSettle();
    expect(find.text('Types du Pokémon · 2 choisis'), findsNothing);

    // Type d'attaque.
    await tester.tap(find.byKey(const ValueKey<String>('meta-move-flying')));
    await tester.pumpAndSettle();
    expect(flambusard, findsOneWidget);
    expect(altaria, findsNothing);
  });

  testWidgets('la fiche de collection ouvre la fiche méta de sa ligue',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flambusard').first);
    await tester.pumpAndSettle();

    final button = find.text('Voir la fiche méta (Super)');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Pires adversaires'), findsOneWidget);
    expect(find.text('Altaria'), findsOneWidget);
  });

  testWidgets('pas de fiche méta pour un Pokémon absent de la méta de sa ligue',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flambusard').first);
    await tester.pumpAndSettle();

    final button = find.widgetWithText(OutlinedButton, 'Absent de la méta Hyper');
    await tester.ensureVisible(button);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
  });

  testWidgets('la mosaïque tient au moins 3 Pokémon par ligne sur un téléphone',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      if (i == 0) {
        await tester.ensureVisible(find.text('Shiny'));
        await tester.tap(find.text('Shiny'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Enregistrer dans la collection'));
      await tester.tap(find.text('Enregistrer dans la collection'));
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    // Largeur d'un téléphone pour la collection.
    tester.view.physicalSize = const Size(360, 1600);
    await tester.pumpAndSettle();
    if (find.byTooltip('Afficher en mosaïque').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Afficher en mosaïque'));
      await tester.pumpAndSettle();
    }
    final tiles = find.byWidgetPredicate(
      (w) => w is Card && (w.key is ValueKey<String>) &&
          (w.key! as ValueKey<String>).value.startsWith('collection-'),
    );
    await tester.scrollUntilVisible(
      tiles.first,
      300,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final rects = tiles.evaluate().map((e) => tester.getRect(find.byWidget(e.widget))).toList();
    expect(rects.length, greaterThanOrEqualTo(3));
    final firstRow = rects.where((r) => (r.top - rects.first.top).abs() < 1).toList();
    expect(firstRow.length, greaterThanOrEqualTo(3));
    for (final r in firstRow) {
      expect(r.width, lessThan(360 / 3));
    }
  });

  testWidgets('exporter puis importer un compte depuis le menu', (tester) async {
    final files = FakeAccountFiles();
    await _pumpApp(tester, files: files);
    await tester.enterText(find.byType(TextField).first, 'Flambusard');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer dans la collection'));
    await tester.tap(find.text('Enregistrer dans la collection'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    final export = find.text('Exporter mon compte');
    final import = find.text('Importer un compte');
    await tester.ensureVisible(import);
    final version = find.textContaining('Version ');
    // Tout en bas, juste au-dessus de la rubrique des mises à jour.
    expect(tester.getTopLeft(export).dy, lessThan(tester.getTopLeft(version).dy));
    expect(tester.getTopLeft(import).dy, lessThan(tester.getTopLeft(version).dy));
    expect(
      tester.getTopLeft(export).dy,
      greaterThan(tester.getTopLeft(find.text('Superposition')).dy),
    );

    await tester.tap(export);
    await tester.pumpAndSettle();
    expect(files.savedName, startsWith('ivhelper-compte-'));
    expect(files.savedContent, contains('Flambusard'));
    expect(find.text('Compte exporté (1 Pokémon).'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Import d'une sauvegarde avec deux Pokémon : remplace après confirmation.
    final saved = jsonDecode(files.savedContent!) as Map<String, Object?>;
    final entries = saved['collection']! as List<Object?>;
    final copy = Map<String, Object?>.of(entries.first! as Map<String, Object?>)
      ..['id'] = 'copie';
    saved['collection'] = <Object?>[...entries, copy];
    files.toPick = jsonEncode(saved);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Importer un compte'));
    await tester.tap(find.text('Importer un compte'));
    await tester.pumpAndSettle();
    expect(find.text('Remplacer ton compte ?'), findsOneWidget);
    await tester.tap(find.text('Importer'));
    await tester.pumpAndSettle();
    expect(find.text('Compte importé (2 Pokémon).'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma collection'));
    await tester.pumpAndSettle();
    expect(find.text('2 Pokémon sur 2'), findsOneWidget);
  });

  testWidgets('un fichier qui n\'est pas une sauvegarde est refusé',
      (tester) async {
    final files = FakeAccountFiles(toPick: 'bonjour');
    await _pumpApp(tester, files: files);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Importer un compte'));
    await tester.tap(find.text('Importer un compte'));
    await tester.pumpAndSettle();
    expect(
      find.text("Ce fichier n'est pas une sauvegarde ivHelper."),
      findsOneWidget,
    );
    expect(find.text('Remplacer ton compte ?'), findsNothing);
  });

  testWidgets('chaînes de recherche : rubrique du menu, espèce et copie',
      (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map<Object?, Object?>)['text']! as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    final entry = find.text('Chaînes de recherche');
    expect(
      tester.getTopLeft(entry).dy,
      lessThan(tester.getTopLeft(find.text('Superposition')).dy),
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();

    // Recherches prêtes à l'emploi, copiables.
    expect(find.text('0-1attaque&3-4défense&3-4PV&PC-1500'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('copy-preset-great')));
    await tester.pumpAndSettle();
    expect(copied.last, '0-1attaque&3-4défense&3-4PV&PC-1500');
    expect(find.text('Chaîne copiée : colle-la dans la recherche du jeu.'), findsOneWidget);

    // Pour une espèce, ligue Super et top 10 par défaut.
    await tester.enterText(
      find.byKey(const ValueKey<String>('search-species')).first,
      'Flambusard',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('+flambusard&0-1attaque&3-4défense&2-4PV&PC-1500'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('search-league-ultra')));
    await tester.pumpAndSettle();
    expect(
      find.text('+flambusard&3-4attaque&3-4défense&3-4PV&PC-2500'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('copy-species')));
    await tester.pumpAndSettle();
    expect(copied.last, '+flambusard&3-4attaque&3-4défense&3-4PV&PC-2500');
  });
}
