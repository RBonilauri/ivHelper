import 'package:material_ui/material_ui.dart';

import '../core/moves.dart';
import '../core/species_repository.dart';
import '../state/team_controller.dart';
import 'type_badge.dart';

const Color _good = Color(0xFF2EAD74);
const Color _bad = Color(0xFFE5484D);

/// Team builder : trois Pokémon, leurs attaques, et l'analyse des types.
class TeamBuilderScreen extends StatelessWidget {
  /// Crée la page pour l'équipe tenue par [team].
  const TeamBuilderScreen({super.key, required this.team});

  /// État de l'équipe.
  final TeamController team;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team builder')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: team,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              for (var i = 0; i < TeamController.size; i++) ...<Widget>[
                _SlotCard(team: team, index: i),
                const SizedBox(height: 12),
              ],
              _SummaryCard(team: team),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.team, required this.index});

  final TeamController team;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slot = team.slots[index];
    final species = slot.species;
    final defense = team.defenseOf(index);
    final offense = team.offenseOf(index);
    return Card(
      key: ValueKey<String>('slot-$index'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Pokémon ${index + 1}', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (species != null) ...<Widget>[
                  for (final t in species.types)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: TypeBadge(t, size: 28),
                    ),
                  IconButton(
                    tooltip: 'Retirer le Pokémon ${index + 1}',
                    icon: const Icon(Icons.close),
                    onPressed: () => team.setSpecies(index, null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _SpeciesField(
              key: ValueKey<String>('species-$index-${species?.nameFr}'),
              repository: team.repository,
              initial: species?.nameFr ?? '',
              label: 'Pokémon ${index + 1} (nom ou numéro)',
              onSelected: (s) => team.setSpecies(index, s),
            ),
            if (species != null) ...<Widget>[
              const SizedBox(height: 10),
              _MovePicker(
                label: 'Attaque immédiate',
                value: slot.fast,
                options: team.fastOptions(index),
                onChanged: (m) => team.setFast(index, m),
              ),
              const SizedBox(height: 8),
              _MovePicker(
                label: 'Attaque chargée 1',
                value: slot.charged1,
                options: team.chargedOptions(index),
                onChanged: (m) => team.setCharged(index, 1, m),
              ),
              const SizedBox(height: 8),
              _MovePicker(
                label: 'Attaque chargée 2',
                value: slot.charged2,
                options: team.chargedOptions(index),
                onChanged: (m) => team.setCharged(index, 2, m),
              ),
            ],
            if (defense != null) ...<Widget>[
              const SizedBox(height: 14),
              _SectionTitle('Défense · selon ses types'),
              _ChipLine(
                label: 'Faible à',
                color: _bad,
                children: <Widget>[
                  for (final w in defense.weaknesses)
                    TypeChip(w.type, factor: w.factor),
                ],
              ),
              _ChipLine(
                label: 'Résiste à',
                color: _good,
                children: <Widget>[
                  for (final r in defense.resistances)
                    TypeChip(r.type, factor: r.factor),
                ],
              ),
            ],
            if (species != null) ...<Widget>[
              const SizedBox(height: 10),
              _SectionTitle('Attaque · selon ses attaques'),
              if (offense == null)
                Text(
                  'Choisis ses attaques pour voir ses cibles.',
                  style: theme.textTheme.bodySmall,
                )
              else ...<Widget>[
                _ChipLine(
                  label: 'Efficace contre',
                  color: _good,
                  children: <Widget>[
                    for (final t in offense.effectiveAgainst) TypeChip(t),
                  ],
                ),
                _ChipLine(
                  label: 'En difficulté contre',
                  color: _bad,
                  children: <Widget>[
                    for (final t in offense.strugglesAgainst) TypeChip(t),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeciesField extends StatelessWidget {
  const _SpeciesField({
    super.key,
    required this.repository,
    required this.initial,
    required this.label,
    required this.onSelected,
  });

  final SpeciesRepository repository;
  final String initial;
  final String label;
  final ValueChanged<Species> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Species>(
      initialValue: TextEditingValue(text: initial),
      displayStringForOption: (s) => s.nameFr,
      optionsBuilder: (value) {
        final text = value.text.trim();
        if (text.isEmpty) return const <Species>[];
        final exact = repository.lookup(text);
        final list = <Species>[
          if (exact != null) exact,
          for (final s in repository.suggest(text, max: 8))
            if (!identical(s, exact)) s,
        ];
        return list;
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search),
        ),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

class _MovePicker extends StatelessWidget {
  const _MovePicker({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final Move? value;
  final List<Move> options;
  final ValueChanged<Move?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('$label-${current?.id}'),
      initialValue: current?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(child: Text('Aucune')),
        for (final m in options)
          DropdownMenuItem<String>(
            value: m.id,
            child: Row(
              children: <Widget>[
                TypeBadge(m.type, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.nameFr, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      onChanged: (id) {
        Move? picked;
        for (final m in options) {
          if (m.id == id) picked = m;
        }
        onChanged(picked);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.team});

  final TeamController team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = team.slots.where((s) => s.species != null).length;
    if (filled == 0) {
      return Text(
        'Ajoute tes Pokémon pour voir le bilan de l\'équipe.',
        style: theme.textTheme.bodyMedium,
      );
    }
    final summary = team.summary;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Bilan de l\'équipe',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            _ChipLine(
              label: 'Faiblesses partagées',
              color: _bad,
              empty: 'Aucune : bonne complémentarité',
              children: <Widget>[
                for (final t in summary.sharedWeaknesses) TypeChip(t),
              ],
            ),
            _ChipLine(
              label: 'Personne ne résiste à',
              color: _bad,
              empty: 'Chaque type est résisté par au moins un',
              children: <Widget>[
                for (final t in summary.unresisted) TypeChip(t),
              ],
            ),
            _ChipLine(
              label: 'Aucune attaque efficace contre',
              color: _bad,
              empty: 'Les 18 types sont couverts',
              children: <Widget>[
                for (final t in summary.uncovered) TypeChip(t),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChipLine extends StatelessWidget {
  const _ChipLine({
    required this.label,
    required this.color,
    required this.children,
    this.empty = 'Aucun',
  });

  final String label;
  final Color color;
  final List<Widget> children;
  final String empty;

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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 4),
          if (children.isEmpty)
            Text(empty, style: theme.textTheme.bodySmall)
          else
            Wrap(spacing: 6, runSpacing: 6, children: children),
        ],
      ),
    );
  }
}
