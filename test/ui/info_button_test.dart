import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/ui/info_button.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('le « i » affiche sa phrase au toucher, puis la referme',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              InfoButton('Rang figé', key: ValueKey<String>('info')),
              SizedBox(height: 300, width: 300),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Rang figé'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('info')));
    await tester.pumpAndSettle();
    expect(find.text('Rang figé'), findsOneWidget);
    await tester.tapAt(const Offset(200, 250));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Rang figé'), findsNothing);
  });
}
