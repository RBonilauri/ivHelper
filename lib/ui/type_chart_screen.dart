import 'package:material_ui/material_ui.dart';

import '../core/poke_type.dart';
import 'type_badge.dart';

const Color _forceRing = Color(0xFF3DDC97);
const Color _weakRing = Color(0xFFFF5A5F);

/// Table des types de Pokémon GO : forces et faiblesses de chaque type.
class TypeChartScreen extends StatelessWidget {
  /// Crée la page de la table des types.
  const TypeChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Table des types')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Super efficace ×1,6 · peu efficace ×0,625 · '
              'immunité ×0,39 (Pokémon GO)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final t in PokeType.values) ...<Widget>[
              _TypeCard(type: t),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final PokeType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey<String>('type-card-${type.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                TypeBadge(type, size: 44),
                const SizedBox(width: 12),
                Text(type.nameFr, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            _BadgeRow(
              label: 'Forces',
              hint: 'efficace contre',
              types: strongAgainst(type),
              ring: _forceRing,
            ),
            _BadgeRow(
              label: 'Peu efficace',
              hint: 'contre',
              types: weakAgainst(type),
            ),
            _BadgeRow(
              label: 'Faiblesses',
              hint: 'craint',
              types: weakTo(type),
              ring: _weakRing,
            ),
            _BadgeRow(
              label: 'Résiste',
              hint: 'à',
              types: resists(type),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({
    required this.label,
    required this.hint,
    required this.types,
    this.ring,
  });

  final String label;
  final String hint;
  final List<PokeType> types;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(
                  text: '$label\n',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ring ?? theme.colorScheme.onSurface,
                  ),
                  children: <InlineSpan>[
                    TextSpan(text: hint, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: types.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Aucun', style: theme.textTheme.bodySmall),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final t in types) TypeBadge(t, size: 32, ring: ring),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
