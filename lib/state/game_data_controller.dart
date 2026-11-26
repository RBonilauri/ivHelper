import 'package:flutter/foundation.dart';

import '../core/game_data.dart';
import '../settings/settings_controller.dart';

/// Squelette.
abstract interface class GameDataSource {
  /// Squelette.
  Future<String> bundledVersion();

  /// Squelette.
  Future<String> bundledSpecies();

  /// Squelette.
  Future<String> bundledMoves();

  /// Squelette.
  Future<String> fetchVersion();

  /// Squelette.
  Future<String> fetchSpecies();

  /// Squelette.
  Future<String> fetchMoves();
}

/// Squelette.
class GameDataController extends ChangeNotifier {
  /// Squelette.
  GameDataController({required this.source, required this.store});

  /// Squelette.
  final GameDataSource source;

  /// Squelette.
  final SettingsStore store;

  /// Squelette.
  GameData get current => GameData.parse(updated: '', speciesJson: '', movesJson: '');

  /// Squelette.
  GameData? get pending => null;

  /// Squelette.
  Future<void> load() async {}

  /// Squelette.
  Future<bool> refresh() async => false;

  /// Squelette.
  bool applyPending() => false;
}
