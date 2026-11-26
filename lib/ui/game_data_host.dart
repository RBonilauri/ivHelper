import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/game_data.dart';
import '../state/game_data_controller.dart';

/// Construit l'appli avec les données du jeu en service. Vérifie au
/// démarrage puis au retour dans l'appli (au plus toutes les [minInterval])
/// si le dépôt a des données plus récentes ; une version téléchargée est mise
/// en service au retour suivant dans l'appli, jamais sous les yeux (l'appli
/// repart alors de l'accueil).
class GameDataHost extends StatefulWidget {
  /// Crée l'hôte.
  const GameDataHost({
    required this.controller,
    required this.builder,
    this.minInterval = const Duration(hours: 6),
    super.key,
  });

  /// Données du jeu ([GameDataController.load] déjà appelé).
  final GameDataController controller;

  /// Construit l'appli avec [GameData].
  final Widget Function(GameData data) builder;

  /// Délai minimal entre deux vérifications en ligne.
  final Duration minInterval;

  @override
  State<GameDataHost> createState() => _GameDataHostState();
}

class _GameDataHostState extends State<GameDataHost>
    with WidgetsBindingObserver {
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    widget.controller.applyPending();
    _check();
  }

  void _check() {
    final now = DateTime.now();
    final last = _lastCheck;
    if (last != null && now.difference(last) < widget.minInterval) return;
    _lastCheck = now;
    unawaited(widget.controller.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final data = widget.controller.current;
        return KeyedSubtree(
          key: ValueKey<String>('game-data-${data.updated}'),
          child: widget.builder(data),
        );
      },
    );
  }
}
