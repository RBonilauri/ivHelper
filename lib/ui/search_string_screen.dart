import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/league.dart';
import '../core/rank_table.dart';
import '../core/search_string.dart';
import '../core/species_repository.dart';
import 'format.dart';
import 'search_field.dart';

/// Chaînes de recherche à coller dans la boîte de Pokémon GO : une chaîne
/// calculée pour une espèce et une ligue, et des recherches prêtes à
/// l'emploi.
class SearchStringScreen extends StatefulWidget {
  /// Crée la page.
  const SearchStringScreen({required this.repository, super.key});

  /// Espèces connues.
  final SpeciesRepository repository;

  @override
  State<SearchStringScreen> createState() => _SearchStringScreenState();
}

class _SearchStringScreenState extends State<SearchStringScreen> {
  String _query = '';
  League _league = League.great;
  int _top = 10;

  Future<void> _copy(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Chaîne copiée : colle-la dans la recherche du jeu.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final species =
        _query.trim().isEmpty ? null : widget.repository.lookup(_query);
    final SearchQuery? result = species == null
        ? null
        : speciesSearch(
            buildRankTable(species.base, cpCap: _league.cpCap, maxLevel: 50),
            name: species.nameFr,
            top: _top,
            cpCap: _league == League.master ? null : _league.cpCap,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Chaînes de recherche')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Text(
              'Copie une chaîne puis colle-la dans la recherche de ta boîte '
              'Pokémon GO pour trouver tes candidats sans évaluer chaque '
              'Pokémon.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Pour une espèce', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SearchField(
              key: const ValueKey<String>('search-species'),
              label: 'Pokémon (nom ou numéro)',
              hint: 'Nosferapti ou 41',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: <Widget>[
                for (final l in League.values)
                  ChoiceChip(
                    key: ValueKey<String>('search-league-${l.key}'),
                    label: Text(l.label),
                    selected: _league == l,
                    onSelected: (_) => setState(() => _league = l),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text('Garder le', style: theme.textTheme.bodyMedium),
                for (final n in const <int>[10, 50, 100])
                  ChoiceChip(
                    key: ValueKey<String>('search-top-$n'),
                    label: Text('top $n'),
                    selected: _top == n,
                    onSelected: (_) => setState(() => _top = n),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_query.trim().isNotEmpty && species == null)
              Text('Pokémon inconnu.', style: theme.textTheme.bodySmall)
            else if (species != null && result != null)
              _QueryCard(
                copyKey: 'copy-species',
                title: '${species.nameFr} · ${_league.label} · top $_top',
                description:
                    'Toute la famille (pré-évolutions comprises). Garde '
                    '${formatGrouped(result.kept)} combinaisons d\'IV sur '
                    '${formatGrouped(result.total)}, dont les $_top '
                    'meilleures : le jeu ne cherche que par tranches '
                    '(0, 1-5, 6-10, 11-14, 15). Vérifie ensuite le rang '
                    'dans ivHelper.',
                text: result.text,
                onCopy: _copy,
              ),
            const SizedBox(height: 20),
            Text('Prêtes à l\'emploi', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in searchPresets) ...<Widget>[
              _QueryCard(
                copyKey: 'copy-preset-${p.id}',
                title: p.title,
                description: p.description,
                text: p.text,
                onCopy: _copy,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Astuce : ajoute « +nom& » au début pour limiter à une '
              'famille, par exemple « +nosferapti& ».',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryCard extends StatelessWidget {
  const _QueryCard({
    required this.copyKey,
    required this.title,
    required this.description,
    required this.text,
    required this.onCopy,
  });

  final String copyKey;
  final String title;
  final String description;
  final String text;
  final Future<void> Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(description, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey<String>(copyKey),
              tooltip: 'Copier',
              icon: const Icon(Icons.copy),
              onPressed: () => onCopy(text),
            ),
          ],
        ),
      ),
    );
  }
}
