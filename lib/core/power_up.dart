import 'collection.dart';

/// Coût pour monter un Pokémon d'un niveau à un autre.
class PowerUpCost {
  /// Crée le coût.
  const PowerUpCost({
    required this.stardust,
    required this.candy,
    required this.xlCandy,
    required this.powerUps,
  });

  /// Poussières d'étoile.
  final int stardust;

  /// Bonbons (jusqu'au niveau 40).
  final int candy;

  /// Bonbons L (au-delà du niveau 40).
  final int xlCandy;

  /// Nombre d'améliorations (une par demi-niveau).
  final int powerUps;
}

/// Poussières d'une amélioration depuis le niveau entier [level] (le même
/// coût vaut pour le demi-niveau suivant). Tableau de Pokémon GO, vérifié
/// sur les totaux connus (1 → 40 : 270 000 ; 40 → 50 : 250 000).
const Map<int, int> _dust = <int, int>{
  1: 200, 2: 200, 3: 400, 4: 400, 5: 600, 6: 600, 7: 800, 8: 800, //
  9: 1000, 10: 1000, 11: 1300, 12: 1300, 13: 1600, 14: 1600, //
  15: 1900, 16: 1900, 17: 2200, 18: 2200, 19: 2500, 20: 2500, //
  21: 3000, 22: 3000, 23: 3500, 24: 3500, 25: 4000, 26: 4000, //
  27: 4500, 28: 4500, 29: 5000, 30: 5000, 31: 6000, 32: 6000, //
  33: 7000, 34: 7000, 35: 8000, 36: 8000, 37: 9000, 38: 9000, //
  39: 10000, 40: 10000, 41: 11000, 42: 11000, 43: 12000, 44: 12000, //
  45: 13000, 46: 13000, 47: 14000, 48: 14000, 49: 15000, //
};

int _candy(int level) {
  if (level <= 10) return 1;
  if (level <= 20) return 2;
  if (level <= 25) return 3;
  if (level <= 30) return 4;
  if (level <= 32) return 6;
  if (level <= 34) return 8;
  if (level <= 36) return 10;
  if (level <= 38) return 12;
  return 15;
}

int _xl(int level) {
  if (level <= 41) return 10;
  if (level <= 43) return 12;
  if (level <= 45) return 15;
  if (level <= 47) return 17;
  return 20;
}

/// Arrondi au supérieur de `value × num / den`, en entiers (sans erreur
/// d'arrondi des décimaux).
int _scaled(int value, int num, int den) => (value * num + den - 1) ~/ den;

/// Coût pour passer du niveau [from] au niveau [to] (demi-niveaux). Le
/// niveau 51 du meilleur ami est gratuit : le coût s'arrête à 50. Obscur :
/// ×1,2 poussières et bonbons ; purifié : ×0,9 ; chanceux : poussières ×0,5
/// (cumulable avec purifié). Chaque amélioration est arrondie au supérieur,
/// comme dans le jeu. `null` si [to] est plus bas que [from].
PowerUpCost? powerUpCost(
  double from,
  double to, {
  bool lucky = false,
  ShadowState shadow = ShadowState.none,
}) {
  if (to < from) return null;
  final (candyNum, candyDen) = switch (shadow) {
    ShadowState.shadow => (12, 10),
    ShadowState.purified => (9, 10),
    ShadowState.none => (1, 1),
  };
  final dustNum = candyNum;
  final dustDen = candyDen * (lucky ? 2 : 1);
  var stardust = 0;
  var candy = 0;
  var xl = 0;
  var steps = 0;
  final start = (from * 2).round();
  final end = (to.clamp(1, 50) * 2).round();
  for (var half = start; half < end; half++) {
    final level = half ~/ 2;
    stardust += _scaled(_dust[level]!, dustNum, dustDen);
    if (level < 40) {
      candy += _scaled(_candy(level), candyNum, candyDen);
    } else {
      xl += _scaled(_xl(level), candyNum, candyDen);
    }
    steps++;
  }
  return PowerUpCost(
    stardust: stardust,
    candy: candy,
    xlCandy: xl,
    powerUps: steps,
  );
}
