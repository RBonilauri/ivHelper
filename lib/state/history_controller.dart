import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/stats.dart';
import '../settings/settings_controller.dart';

/// Une recherche récente : espèce et IV.
@immutable
class HistoryItem {
  /// Crée une recherche.
  const HistoryItem(this.speciesName, this.iv);

  /// Nom de l'espèce.
  final String speciesName;

  /// IV saisis.
  final Iv iv;
}

/// Dernières recherches de l'écran de rang, une par espèce, la plus récente
/// d'abord.
class HistoryController extends ChangeNotifier {
  /// Crée l'historique adossé à [store].
  HistoryController(this.store);

  /// Nombre de recherches gardées.
  static const int maxItems = 8;

  /// Stockage.
  final SettingsStore store;

  final List<HistoryItem> _items = <HistoryItem>[];
  bool _disposed = false;

  /// Recherches, la plus récente d'abord.
  List<HistoryItem> get items => List<HistoryItem>.unmodifiable(_items);

  /// Note la recherche de [speciesName] avec [iv] : elle remplace la
  /// précédente de la même espèce et passe en tête.
  void record(String speciesName, Iv iv) {
    if (_items.isNotEmpty &&
        _items.first.speciesName == speciesName &&
        _items.first.iv == iv) {
      return;
    }
    _items
      ..removeWhere((h) => h.speciesName == speciesName)
      ..insert(0, HistoryItem(speciesName, iv));
    if (_items.length > maxItems) _items.removeRange(maxItems, _items.length);
    _changed();
  }

  /// Efface l'historique.
  void clear() {
    _items.clear();
    _changed();
  }

  /// Recharge l'historique enregistré ; ignore une sauvegarde illisible.
  Future<void> load() async {
    final raw = await store.readHistory();
    if (raw == null || _disposed) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! List<dynamic>) return;
    _items.clear();
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['species'];
      final iv = item['iv'];
      if (name is! String || iv is! List<dynamic> || iv.length != 3) continue;
      if (iv.any((v) => v is! int || v < 0 || v > 15)) continue;
      _items.add(HistoryItem(name, Iv(iv[0] as int, iv[1] as int, iv[2] as int)));
      if (_items.length >= maxItems) break;
    }
    notifyListeners();
  }

  void _changed() {
    if (_disposed) return;
    notifyListeners();
    unawaited(
      store.writeHistory(
        jsonEncode(<Map<String, Object>>[
          for (final h in _items)
            <String, Object>{
              'species': h.speciesName,
              'iv': <int>[h.iv.atk, h.iv.def, h.iv.sta],
            },
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
