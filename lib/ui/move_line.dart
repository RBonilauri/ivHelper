import 'package:material_ui/material_ui.dart';

import '../core/moves.dart';
import 'move_label.dart';
import 'type_badge.dart';

/// Une attaque dans une fiche : type, nom, barres d'énergie (chargée),
/// puissance et changements de stats.
class MoveLine extends StatelessWidget {
  /// Crée la ligne de [move], affichée sous le nom [label].
  const MoveLine({
    required this.move,
    required this.label,
    super.key,
    this.bold = false,
  });

  /// Attaque affichée.
  final Move move;

  /// Nom affiché (avec l'astérisque d'une attaque d'événement).
  final String label;

  /// Vrai pour mettre le nom en gras (attaque de la méta).
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TypeBadge(move.type, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: bold ? FontWeight.w800 : null,
                  ),
                ),
              ),
              if (move.chargeBars > 0) ...<Widget>[
                ChargeBars(move: move),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: 36,
                child: Text(
                  '${move.power}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          for (final change in move.effects)
            for (final text in effectLabels(change))
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 36, top: 2),
                child: _Effect(text: text, good: change.isBeneficial),
              ),
        ],
      ),
    );
  }
}

class _Effect extends StatelessWidget {
  const _Effect({required this.text, required this.good});

  final String text;
  final bool good;

  static const Color _good = Color(0xFF2EAD74);
  static const Color _bad = Color(0xFFD9467A);

  @override
  Widget build(BuildContext context) {
    final color = good ? _good : _bad;
    final down = text.contains('−');
    return Row(
      children: <Widget>[
        Icon(
          down ? Icons.arrow_downward : Icons.arrow_upward,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

/// Barres d'énergie d'une attaque chargée, de la couleur de son type : une
/// longue barre pour une attaque coûteuse, deux ou trois pour une courte.
class ChargeBars extends StatelessWidget {
  /// Crée les barres de [move].
  const ChargeBars({required this.move, super.key});

  /// Attaque chargée.
  final Move move;

  /// Largeur totale, quel que soit le nombre de barres.
  static const double width = 72;

  @override
  Widget build(BuildContext context) {
    final count = move.chargeBars;
    const gap = 4.0;
    final segment = (width - gap * (count - 1)) / count;
    final color = typeColors[move.type]!;
    return Semantics(
      label: '$count barre${count > 1 ? 's' : ''} d\'énergie',
      child: Row(
        key: ValueKey<String>('charge-bars-${move.id}'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < count; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: gap),
            Transform(
              transform: Matrix4.skewX(-0.35),
              alignment: Alignment.center,
              child: Container(
                key: const ValueKey<String>('charge-bar'),
                width: segment,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
