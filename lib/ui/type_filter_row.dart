import 'package:material_ui/material_ui.dart';

import '../core/poke_type.dart';
import 'collection_widgets.dart';
import 'type_badge.dart';

/// Rangée de types à toucher pour filtrer (un ou plusieurs), avec le nombre
/// de Pokémon concernés sous chaque pastille ; seuls les types présents (ou
/// déjà cochés) sont proposés.
class TypeFilterRow extends StatelessWidget {
  /// Crée la rangée.
  const TypeFilterRow({
    required this.title,
    required this.counts,
    required this.selected,
    required this.onChanged,
    required this.keyPrefix,
    super.key,
    this.hint,
  });

  /// Titre (« Types »), suivi du nombre de types cochés.
  final String title;

  /// Titre quand rien n'est coché (par défaut, [title]).
  final String? hint;

  /// Nombre de Pokémon par type.
  final Map<PokeType, int> counts;

  /// Types cochés.
  final Set<PokeType> selected;

  /// Appelé avec la nouvelle sélection.
  final ValueChanged<Set<PokeType>> onChanged;

  /// Préfixe des clés des pastilles (`<prefix>-<type>`).
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = <PokeType>[
      for (final t in PokeType.values)
        if (counts.containsKey(t) || selected.contains(t)) t,
    ];
    if (types.isEmpty) return const SizedBox.shrink();
    final n = selected.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                n == 0 ? hint ?? title : '$title · $n choisi${n > 1 ? 's' : ''}',
                style: theme.textTheme.labelLarge,
              ),
            ),
            if (n > 0)
              TextButton(
                onPressed: () => onChanged(const <PokeType>{}),
                child: const Text('Tous les types'),
              ),
          ],
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final t = types[i];
              final on = selected.contains(t);
              final dim = n > 0 && !on;
              return Semantics(
                button: true,
                selected: on,
                label: '${t.nameFr}, ${counts[t] ?? 0} Pokémon',
                child: InkWell(
                  key: ValueKey<String>('$keyPrefix-${t.id}'),
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(<PokeType>{
                    for (final x in selected)
                      if (x != t) x,
                    if (!on) t,
                  }),
                  child: Opacity(
                    opacity: dim ? 0.35 : 1,
                    child: ExcludeSemantics(
                      child: Column(
                        children: <Widget>[
                          TypeBadge(t, size: 40, ring: on ? rankOneGold : null),
                          const SizedBox(height: 2),
                          Text(
                            '${counts[t] ?? 0}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: on ? FontWeight.w800 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
