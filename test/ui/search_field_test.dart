import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/ui/app_theme.dart';
import 'package:ivhelper/ui/search_field.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('la croix n\'apparaît qu\'avec du texte et vide le champ',
      (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchField(label: 'Filtrer par nom', onChanged: changes.add),
        ),
      ),
    );
    expect(find.byTooltip('Effacer'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Alta');
    await tester.pump();
    expect(find.byTooltip('Effacer'), findsOneWidget);
    await tester.tap(find.byTooltip('Effacer'));
    await tester.pump();
    expect(find.text('Alta'), findsNothing);
    expect(changes.last, '');
    expect(find.byTooltip('Effacer'), findsNothing);
  });

  test('le texte indicatif des champs vides est gris et en italique', () {
    for (final brightness in Brightness.values) {
      final theme = buildTheme(brightness);
      final decoration = theme.inputDecorationTheme;
      final grey = theme.colorScheme.onSurfaceVariant;
      expect(decoration.labelStyle?.fontStyle, FontStyle.italic);
      expect(decoration.labelStyle?.color, grey);
      expect(decoration.hintStyle?.fontStyle, FontStyle.italic);
      expect(decoration.hintStyle?.color, grey);
      // Une fois le champ rempli, l'étiquette remonte en style normal.
      expect(decoration.floatingLabelStyle?.fontStyle, FontStyle.normal);
    }
  });
}
