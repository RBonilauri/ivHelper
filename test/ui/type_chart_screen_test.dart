import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/ui/app_theme.dart';
import 'package:ivhelper/ui/type_chart_screen.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: buildTheme(Brightness.light), home: const TypeChartScreen()),
  );
}

Finder _in(String group, PokeType type) => find.descendant(
      of: find.byKey(ValueKey<String>(group)),
      matching: find.byKey(ValueKey<String>('badge-${type.id}')),
    );

Future<void> _pick(WidgetTester tester, PokeType type) async {
  await tester.tap(find.byKey(ValueKey<String>('type-pick-${type.id}')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les 18 types tiennent sur une grille compacte en haut',
      (tester) async {
    await _pump(tester);
    for (final t in PokeType.values) {
      expect(find.byKey(ValueKey<String>('type-pick-${t.id}')), findsOneWidget);
    }
    // Six par ligne : trois lignes, pas une longue liste de cartes.
    final tops = <double>{
      for (final t in PokeType.values)
        tester.getTopLeft(find.byKey(ValueKey<String>('type-pick-${t.id}'))).dy,
    };
    expect(tops, hasLength(3));
    expect(find.text('Touche un type, ou deux pour un double type.'), findsOneWidget);
  });

  testWidgets('un type : sa défense et son attaque, immunités à part',
      (tester) async {
    await _pump(tester);
    await _pick(tester, PokeType.normal);
    expect(_in('def-×1,6', PokeType.fighting), findsOneWidget);
    expect(_in('def-×0,39', PokeType.ghost), findsOneWidget);
    expect(_in('atk-normal-×0,625', PokeType.rock), findsOneWidget);
    expect(_in('atk-normal-×0,625', PokeType.steel), findsOneWidget);
    expect(_in('atk-normal-×0,39', PokeType.ghost), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('atk-normal-×1,6')), findsNothing);
  });

  testWidgets('deux types : la défense cumule les multiplicateurs',
      (tester) async {
    await _pump(tester);
    await _pick(tester, PokeType.water);
    await _pick(tester, PokeType.ground);
    expect(find.text('Eau / Sol en défense'), findsOneWidget);
    expect(_in('def-×2,56', PokeType.grass), findsOneWidget);
    expect(_in('def-×0,625', PokeType.electric), findsOneWidget);
    // Une section d'attaque par type choisi.
    expect(find.byKey(const ValueKey<String>('atk-water')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('atk-ground')), findsOneWidget);
  });

  testWidgets('toucher un type choisi le retire ; un troisième remplace le second',
      (tester) async {
    await _pump(tester);
    await _pick(tester, PokeType.water);
    await _pick(tester, PokeType.ground);
    await _pick(tester, PokeType.fire);
    expect(find.text('Eau / Feu en défense'), findsOneWidget);
    await _pick(tester, PokeType.water);
    expect(find.text('Feu en défense'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('atk-water')), findsNothing);
  });
}
