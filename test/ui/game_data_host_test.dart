import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/game_data_controller.dart';
import 'package:ivhelper/ui/game_data_host.dart';

import '../support/fake_game_data.dart';

void main() {
  testWidgets(
      'nouvelles données appliquées au retour dans l\'appli, jamais sous les yeux',
      (tester) async {
    final controller = GameDataController(
      source: FakeGameDataSource(remoteUpdated: '2026-11-27'),
      store: MemorySettingsStore(),
    );
    await controller.load();
    await tester.pumpWidget(
      GameDataHost(
        controller: controller,
        builder: (data) => Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '${data.updated} ${data.species.findByName('Flambusard')!.base.atk}',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Téléchargées au démarrage, mais pas appliquées pendant l'utilisation.
    expect(controller.pending?.updated, '2026-11-27');
    expect(find.text('2026-11-20 176'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('2026-11-27 200'), findsOneWidget);
  });
}
