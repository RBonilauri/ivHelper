import 'package:flutter/foundation.dart';

import '../core/rank_service.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';

/// État de l'écran de saisie : espèce, IV, niveau maximal et résultats.
class LookupController extends ChangeNotifier {
  /// Crée un contrôleur adossé au [repository] d'espèces.
  LookupController(this.repository);

  /// Espèces connues.
  final SpeciesRepository repository;

  String _query = '';
  Species? _species;
  Iv _iv = const Iv(15, 15, 15);
  double _maxLevel = 50;
  int _minIv = 0;
  RankResult? _result;

  /// Texte saisi (nom ou numéro).
  String get query => _query;

  /// Espèce reconnue, ou `null`.
  Species? get species => _species;

  /// IV saisis.
  Iv get iv => _iv;

  /// Niveau maximal pris en compte (50, ou 51 avec le bonus meilleur ami).
  double get maxLevel => _maxLevel;

  /// Plancher d'IV appliqué au classement (0 ou 10).
  int get minIv => _minIv;

  /// Résultats en ligue super et hyper, ou `null` sans espèce reconnue.
  RankResult? get result => _result;

  /// Vrai si une saisie non vide ne correspond à aucune espèce.
  bool get hasUnknownQuery => _query.trim().isNotEmpty && _species == null;

  /// Espèces proposées pour la saisie en cours.
  List<Species> get suggestions => repository.suggest(_query);

  /// Met à jour la saisie et l'espèce reconnue.
  void setQuery(String value) {
    _query = value;
    final found = repository.lookup(value);
    if (!identical(found, _species)) {
      _species = found;
      _recompute();
    }
    notifyListeners();
  }

  /// Choisit [species] parmi les suggestions.
  void selectSpecies(Species species) {
    _query = species.nameFr;
    _species = species;
    _recompute();
    notifyListeners();
  }

  /// Change les IV saisis.
  void setIv(Iv value) {
    if (value == _iv) return;
    _iv = value;
    _recompute();
    notifyListeners();
  }

  /// Change le niveau maximal (50 ou 51).
  void setMaxLevel(double value) {
    if (value == _maxLevel) return;
    _maxLevel = value;
    _recompute();
    notifyListeners();
  }

  /// Change le plancher d'IV (0 : aucun, 10 : 10/10/10).
  ///
  /// Les IV saisis sous le plancher sont relevés jusqu'à lui.
  void setMinIv(int value) {
    if (value == _minIv) return;
    _minIv = value;
    _iv = Iv(
      _iv.atk < value ? value : _iv.atk,
      _iv.def < value ? value : _iv.def,
      _iv.sta < value ? value : _iv.sta,
    );
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    final s = _species;
    _result = s == null ? null : rankIv(s.base, _iv, maxLevel: _maxLevel, minIv: _minIv);
  }
}
