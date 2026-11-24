import 'package:material_ui/material_ui.dart';

/// Saisie d'un IV comme la barre d'évaluation du jeu : 15 segments à toucher
/// ou à glisser, plus les boutons moins et plus pour l'ajustement fin.
class IvBar extends StatelessWidget {
  /// Crée la barre de l'IV [label].
  const IvBar({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  /// Nom de la stat (Atk, Déf, PV).
  final String label;

  /// Valeur actuelle, de [min] à 15.
  final int value;

  /// Plus petite valeur permise (0, ou 10 avec le plancher 10/10/10).
  final int min;

  /// Appelé avec la nouvelle valeur.
  final ValueChanged<int> onChanged;

  /// Couleur des segments pleins (rouge quand la stat est parfaite, comme
  /// dans le jeu).
  static Color fillColor(int value) =>
      value == 15 ? const Color(0xFFE5484D) : const Color(0xFFF5A623);

  int _valueAt(double dx, double width) {
    if (width <= 0) return value;
    final raw = (dx / width * 15).ceil();
    return raw.clamp(min, 15);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: 'IV $label',
      value: '$value sur 15',
      increasedValue: value < 15 ? '${value + 1}' : null,
      decreasedValue: value > min ? '${value - 1}' : null,
      onIncrease: value < 15 ? () => onChanged(value + 1) : null,
      onDecrease: value > min ? () => onChanged(value - 1) : null,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  key: ValueKey<String>('iv-bar-$label'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => onChanged(_valueAt(d.localPosition.dx, width)),
                  onHorizontalDragUpdate: (d) =>
                      onChanged(_valueAt(d.localPosition.dx, width)),
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: Row(
                        children: <Widget>[
                          for (var i = 1; i <= 15; i++)
                            Expanded(
                              child: Container(
                                height: 14,
                                margin: EdgeInsetsDirectional.only(
                                  end: i % 5 == 0 && i < 15 ? 4 : 1,
                                ),
                                decoration: BoxDecoration(
                                  color: i <= value
                                      ? fillColor(value)
                                      : (i <= min
                                          ? scheme.outlineVariant
                                          : scheme.surfaceContainerHighest),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(i == 1 ? 7 : 0),
                                    right: Radius.circular(i == 15 ? 7 : 0),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Diminuer $label',
            visualDensity: VisualDensity.compact,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              key: ValueKey<String>('iv-value-$label'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Augmenter $label',
            visualDensity: VisualDensity.compact,
            onPressed: value < 15 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Lit « 15/14/13 », « 15 14 13 » ou « 151413 » : trois IV de 0 à 15, ou
/// `null`.
List<int>? parseIvText(String input) {
  final parts = RegExp(r'\d+').allMatches(input).map((m) => m.group(0)!).toList();
  List<int>? valid(List<int> v) =>
      v.length == 3 && v.every((x) => x >= 0 && x <= 15) ? v : null;
  if (parts.length == 3) return valid(parts.map(int.parse).toList());
  if (parts.length == 1) {
    final d = parts.single;
    // Six chiffres : trois nombres à deux chiffres (« 151413 », « 001510 »).
    if (d.length == 6) {
      return valid(<int>[
        int.parse(d.substring(0, 2)),
        int.parse(d.substring(2, 4)),
        int.parse(d.substring(4, 6)),
      ]);
    }
  }
  return null;
}
