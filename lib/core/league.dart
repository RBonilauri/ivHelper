/// Ligue PvP de Pokémon GO.
enum League {
  /// Ligue mini (500 PC).
  little('little', 'Mini', '500', 500),

  /// Ligue super (1500 PC).
  great('great', 'Super', '1500', 1500),

  /// Ligue hyper (2500 PC).
  ultra('ultra', 'Hyper', '2500', 2500),

  /// Ligue master (sans limite).
  master('master', 'Master', 'sans limite', 10000);

  const League(this.key, this.label, this.capLabel, this.cpCap);

  /// Clé enregistrée en JSON.
  final String key;

  /// Nom affiché.
  final String label;

  /// Plafond affiché.
  final String capLabel;

  /// Plafond de PC utilisé pour le classement.
  final int cpCap;

  /// Ligue de clé [key], ou `null`.
  static League? fromKey(Object? key) {
    for (final l in values) {
      if (l.key == key) return l;
    }
    return null;
  }
}
