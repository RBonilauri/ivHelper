import 'package:material_ui/material_ui.dart';

import '../core/poke_type.dart';
import 'collection_widgets.dart';
import 'type_badge.dart';

const Color _good = Color(0xFF2EAD74);
const Color _bad = Color(0xFFD9467A);

/// Libellé d'un multiplicateur de Pokémon GO (×1,6, ×0,625, ×0,39…).
String _factorLabel(double factor) {
  return switch ((factor * 1000).round()) {
    2560 => '×2,56',
    1600 => '×1,6',
    625 => '×0,625',
    391 => '×0,39',
    244 => '×0,24',
    153 => '×0,15',
    _ => formatFactor(factor),
  };
}

/// Table des types de Pokémon GO : on choisit un type (ou deux, pour un
/// double type) dans une grille compacte, et seule son analyse s'affiche.
class TypeChartScreen extends StatefulWidget {
  /// Crée la page de la table des types.
  const TypeChartScreen({super.key});

  @override
  State<TypeChartScreen> createState() => _TypeChartScreenState();
}

class _TypeChartScreenState extends State<TypeChartScreen> {
  /// Types choisis, dans l'ordre (deux au plus).
  List<PokeType> _picked = const <PokeType>[];

  void _toggle(PokeType t) {
    setState(() {
      if (_picked.contains(t)) {
        _picked = <PokeType>[
          for (final p in _picked)
            if (p != t) p,
        ];
      } else if (_picked.length < 2) {
        _picked = <PokeType>[..._picked, t];
      } else {
        _picked = <PokeType>[_picked.first, t];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Table des types')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: <Widget>[
            Text(
              'Touche un type, ou deux pour un double type.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _TypeGrid(picked: _picked, onTap: _toggle),
            const SizedBox(height: 4),
            Text(
              'Pokémon GO : super efficace ×1,6 · peu efficace ×0,625 · '
              'sans effet ×0,39',
              style: theme.textTheme.bodySmall,
            ),
            if (_picked.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _DefenseCard(types: _picked),
              for (final t in _picked) ...<Widget>[
                const SizedBox(height: 10),
                _AttackCard(type: t),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Les 18 types, six par ligne.
class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.picked, required this.onTap});

  final List<PokeType> picked;
  final ValueChanged<PokeType> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const perRow = 6;
    const types = PokeType.values;
    return Column(
      children: <Widget>[
        for (var row = 0; row * perRow < types.length; row++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = row * perRow; i < (row + 1) * perRow; i++)
                Expanded(
                  child: i >= types.length
                      ? const SizedBox.shrink()
                      : _GridCell(
                          type: types[i],
                          selected: picked.contains(types[i]),
                          dimmed: picked.isNotEmpty &&
                              !picked.contains(types[i]),
                          onTap: () => onTap(types[i]),
                          style: theme.textTheme.labelSmall,
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.type,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    required this.style,
  });

  final PokeType type;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: type.nameFr,
      child: InkWell(
        key: ValueKey<String>('type-pick-${type.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: <Widget>[
                  TypeBadge(type, size: 38, ring: selected ? rankOneGold : null),
                  const SizedBox(height: 2),
                  Text(
                    type.nameFr,
                    textAlign: TextAlign.center,
                    style: style?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dégâts subis par un Pokémon de ces types, groupés par multiplicateur.
class _DefenseCard extends StatelessWidget {
  const _DefenseCard({required this.types});

  final List<PokeType> types;

  @override
  Widget build(BuildContext context) {
    final groups = <double, List<PokeType>>{};
    for (final a in PokeType.values) {
      final f = effectiveness(a, types);
      if ((f - 1).abs() < 1e-9) continue;
      groups.putIfAbsent(f, () => <PokeType>[]).add(a);
    }
    final factors = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return _Section(
      key: const ValueKey<String>('defense'),
      title: '${types.map((t) => t.nameFr).join(' / ')} en défense',
      subtitle: 'Dégâts subis selon le type de l\'attaque',
      children: <Widget>[
        for (final f in factors)
          _FactorRow(
            groupKey: 'def-${_factorLabel(f)}',
            factor: _factorLabel(f),
            caption: f > 1 ? 'faible' : (f < 0.5 ? 'très résistant' : 'résiste'),
            color: f > 1 ? _bad : _good,
            types: groups[f]!,
          ),
      ],
    );
  }
}

/// Efficacité d'une attaque de ce type contre chaque type.
class _AttackCard extends StatelessWidget {
  const _AttackCard({required this.type});

  final PokeType type;

  @override
  Widget build(BuildContext context) {
    final strong = <PokeType>[];
    final weak = <PokeType>[];
    final none = <PokeType>[];
    for (final d in PokeType.values) {
      final f = singleEffectiveness(type, d);
      if (f > 1) {
        strong.add(d);
      } else if (f == immune) {
        none.add(d);
      } else if (f < 1) {
        weak.add(d);
      }
    }
    final id = 'atk-${type.id}';
    return _Section(
      key: ValueKey<String>(id),
      title: 'Attaque ${type.nameFr}',
      subtitle: 'Dégâts infligés à un Pokémon de chaque type',
      children: <Widget>[
        if (strong.isNotEmpty)
          _FactorRow(
            groupKey: '$id-×1,6',
            factor: '×1,6',
            caption: 'super efficace',
            color: _good,
            types: strong,
          ),
        if (weak.isNotEmpty)
          _FactorRow(
            groupKey: '$id-×0,625',
            factor: '×0,625',
            caption: 'peu efficace',
            color: _bad,
            types: weak,
          ),
        if (none.isNotEmpty)
          _FactorRow(
            groupKey: '$id-×0,39',
            factor: '×0,39',
            caption: 'sans effet',
            color: _bad,
            types: none,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleMedium),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            if (children.isEmpty)
              Text('Aucun multiplicateur particulier.', style: theme.textTheme.bodySmall)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

/// Une ligne : le multiplicateur à gauche, les types concernés à droite.
class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.groupKey,
    required this.factor,
    required this.caption,
    required this.color,
    required this.types,
  });

  final String groupKey;
  final String factor;
  final String caption;
  final Color color;
  final List<PokeType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey<String>(groupKey),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  factor,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(caption, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                for (final t in types)
                  KeyedSubtree(
                    key: ValueKey<String>('badge-${t.id}'),
                    child: TypeBadge(t, size: 30),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
