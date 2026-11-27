import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/meta.dart';
import '../core/moves.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';
import '../overlay/overlay_services.dart';
import '../settings/account_backup.dart';
import '../settings/account_files.dart';
import '../settings/settings_controller.dart';
import '../state/collection_controller.dart';
import '../state/history_controller.dart';
import '../state/lookup_controller.dart';
import '../state/meta_controller.dart';
import '../state/team_controller.dart';
import '../state/update_controller.dart';
import 'collection_detail_screen.dart';
import 'collection_screen.dart';
import 'iv_bar.dart';
import 'iv_logo.dart';
import 'meta_screen.dart';
import 'result_panel.dart';
import 'save_pokemon_sheet.dart';
import 'search_field.dart';
import 'search_string_screen.dart';
import 'settings_drawer.dart';
import 'team_builder_screen.dart';
import 'type_badge.dart';
import 'type_chart_screen.dart';
import 'update_banner.dart';

/// Écran unique : saisie de l'espèce et des IV, résultats Mini, Super, Hyper et Master.
class HomeScreen extends StatefulWidget {
  /// Crée l'écran à partir du [repository] d'espèces.
  const HomeScreen({
    super.key,
    required this.repository,
    required this.moves,
    required this.settings,
    required this.metaSource,
    required this.updateSource,
    required this.currentBuild,
    required this.overlayLauncher,
    this.launchActions,
    required this.accountFiles,
    this.gameDataUpdated,
  });

  /// Lancement de la pastille flottante.
  final OverlayLauncher overlayLauncher;

  /// Lancements rapides de la pastille, ou `null`.
  final LaunchActions? launchActions;

  /// Fichiers de sauvegarde du compte (export et import).
  final AccountFiles accountFiles;

  /// Source des mises à jour de l'app.
  final UpdateSource updateSource;

  /// Numéro de build de l'app installée.
  final int currentBuild;

  /// Date des données du jeu en service, affichée dans le menu.
  final String? gameDataUpdated;

  /// Source de la méta PvPoke.
  final MetaSource metaSource;

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Attaques connues, pour le team builder.
  final MoveBook moves;

  /// Réglages d'affichage, modifiables depuis la barre latérale.
  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final LookupController _controller =
      LookupController(widget.repository);
  final TextEditingController _text = TextEditingController();
  late final TeamController _team = TeamController(
    repository: widget.repository,
    moves: widget.moves,
    store: widget.settings.store,
  );

  late final HistoryController _history =
      HistoryController(widget.settings.store);
  late final CollectionController _collection = CollectionController(
    repository: widget.repository,
    moves: widget.moves,
    store: widget.settings.store,
  );
  League _league = League.great;
  late final UpdateController _update = UpdateController(
    source: widget.updateSource,
    currentBuild: widget.currentBuild,
  );
  late final MetaController _meta = MetaController(
    source: widget.metaSource,
    store: widget.settings.store,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_team.load());
    unawaited(_collection.load());
    unawaited(_history.load());
    _controller.addListener(_recordHistory);
    WidgetsBinding.instance.addObserver(this);
    // La méta sert aussi à mettre en évidence les attaques recommandées.
    unawaited(_meta.ensureLoaded());
    // Les compilations locales (build 0) ne cherchent pas de mise à jour au
    // démarrage ; le bouton du menu reste disponible.
    if (widget.currentBuild > 0) unawaited(_update.check());
    // Raccourci de l'icône ou tuile des réglages rapides : pastille directe.
    widget.launchActions?.listen(() => unawaited(_quickBubble()));
  }

  /// Lance la pastille sans passer par le menu, puis revient à l'appli
  /// précédente (le jeu) ; en cas de refus, le message reste dans l'appli.
  Future<void> _quickBubble() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final error = await widget.overlayLauncher.start();
    if (!mounted) return;
    if (error == null) {
      await widget.launchActions?.leaveApp();
      return;
    }
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(duration: const Duration(seconds: 6), content: Text(error)),
      );
  }

  void _openCollection(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CollectionScreen(
            collection: _collection,
            onOpen: _openEntry,
            metaMoves: _metaMoves,
            metaLink: CollectionMetaLink(
              entryFor: (entry, league) => _meta.data?.entryFor(
                entry.speciesName,
                league,
                shadow: entry.shadow == ShadowState.shadow,
              ),
              actions: _metaActions,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // La pastille a pu enregistrer des Pokémon pendant que l'app était en
    // arrière-plan : on relit le stockage.
    unawaited(_reloadShared());
  }

  Future<void> _reloadShared() async {
    await widget.settings.store.refresh();
    await _collection.load();
  }

  Future<void> _startOverlay(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await widget.overlayLauncher.start();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            error ??
                'Pastille lancée : ouvre un Pokémon dans Pokémon GO, touche '
                    'Évaluer pour voir les barres, puis touche la pastille.',
          ),
        ),
      );
  }

  void _recordHistory() {
    final species = _controller.species;
    if (species != null) _history.record(species.nameFr, _controller.iv);
  }

  /// Affiche [species] avec [iv] sur l'écran de rang.
  void _show(Species species, Iv iv, {double? maxLevel}) {
    final lowest = <int>[iv.atk, iv.def, iv.sta].reduce((a, b) => a < b ? a : b);
    if (lowest < _controller.minIv) _controller.setMinIv(0);
    _controller.selectSpecies(species);
    if (maxLevel != null) _controller.setMaxLevel(maxLevel);
    _controller.setIv(iv);
    _text.text = species.nameFr;
  }

  /// Applique une saisie rapide « 15/14/13 ».
  void _quickIv(String text) {
    final v = parseIvText(text);
    if (v == null) return;
    final iv = Iv(v[0], v[1], v[2]);
    if (v.any((x) => x < _controller.minIv)) _controller.setMinIv(0);
    _controller.setIv(iv);
  }

  void _openEntry(BuildContext context, CollectionEntry entry) {
    final species = widget.repository.findByName(entry.speciesName);
    if (species == null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _show(species, entry.iv, maxLevel: entry.maxLevel);
  }

  void _save(BuildContext context) {
    final species = _controller.species;
    if (species == null) return;
    final iv = _controller.iv;
    final maxLevel = _controller.maxLevel;
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      showSaveSheet(
        context,
        SavePokemonSheet(
          species: species,
          iv: iv,
          moves: widget.moves,
          initialLeague: _league,
          metaMoves: _metaMoves,
          rankFor: (league) =>
              _collection.rankFor(species, iv, maxLevel, league),
          onSave: (options) {
            final entry = _collection.add(species, iv, maxLevel, options);
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 5),
                  persist: false,
                  content: Text(
                    '${species.nameFr} ${iv.atk}/${iv.def}/${iv.sta} '
                    'enregistré (${entry.league.label}, rang ${entry.rank})',
                  ),
                  action: SnackBarAction(
                    label: 'Voir',
                    onPressed: () {
                      if (context.mounted) _openCollection(context);
                    },
                  ),
                ),
              );
          },
        ),
      ),
    );
  }

  void _openTeam(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TeamBuilderScreen(
            team: _team,
            collection: _collection,
            meta: _meta,
          ),
        ),
      ),
    );
  }

  /// Exporte le compte dans un fichier choisi par l'utilisateur.
  Future<void> _exportAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final now = DateTime.now();
      final text = await exportAccount(widget.settings.store, now: now);
      final count = previewAccount(text).pokemonCount;
      final saved = await widget.accountFiles.save(accountFileName(now), text);
      if (!saved) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Compte exporté ($count Pokémon).')),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export impossible : $e')));
    }
  }

  /// Importe un compte : vérifie le fichier, demande confirmation, remplace
  /// les données puis recharge l'app.
  Future<void> _importAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final String? text;
    try {
      text = await widget.accountFiles.pick();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import impossible : $e')));
      return;
    }
    if (text == null) return;
    final AccountSummary summary;
    try {
      summary = previewAccount(text);
    } on AccountImportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remplacer ton compte ?'),
        content: Text(
          'Ta collection, ton équipe, tes dernières recherches et tes réglages '
          "seront remplacés par ceux du fichier (${summary.pokemonCount} "
          'Pokémon).',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await importAccount(widget.settings.store, text);
    await widget.settings.load();
    await _collection.load();
    await _team.load();
    await _history.load();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Compte importé (${summary.pokemonCount} Pokémon).'),
      ),
    );
  }

  /// Actions de la fiche méta (onglet Méta et fiche de collection).
  MetaActions get _metaActions => MetaActions(
        ownedRank: _ownedRank,
        isOwned: (name) => _collection.ownedSpecies
            .contains(name.replaceFirst(' (Obscur)', '')),
        checkIvs: _checkIvs,
        addToTeam: (context, entry) => unawaited(_addToTeam(context, entry)),
        moves: widget.moves,
      );

  /// Attaques recommandées par la méta pour [species] dans [league].
  List<String> _metaMoves(Species species, League league, ShadowState shadow) =>
      _meta.data?.movesetForAnyLeague(
        species.nameFr,
        league.key,
        shadow: shadow == ShadowState.shadow,
      ) ??
      const <String>[];

  /// Meilleur rang en collection pour [entry] dans [league] : même espèce,
  /// même état obscur, tag de la ligue.
  int? _ownedRank(MetaEntry entry, MetaLeague league) {
    final target = League.fromKey(league.key);
    int? best;
    for (final e in _collection.entries) {
      if (e.speciesName != entry.species || e.league != target) continue;
      if ((e.shadow == ShadowState.shadow) != entry.shadow) continue;
      if (best == null || e.rank < best) best = e.rank;
    }
    return best;
  }

  void _checkIvs(BuildContext context, MetaEntry entry) {
    final species = widget.repository.findByName(entry.species ?? '');
    if (species == null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _controller.selectSpecies(species);
    _text.text = species.nameFr;
  }

  Future<void> _addToTeam(BuildContext context, MetaEntry entry) async {
    final species = widget.repository.findByName(entry.species ?? '');
    if (species == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final slots = _team.slots;
    final index = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Ajouter dans quel emplacement ?'),
        children: <Widget>[
          for (var i = 0; i < slots.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(i),
              child: Text(
                'Emplacement ${i + 1} · '
                '${slots[i].species?.nameFr ?? 'vide'}',
              ),
            ),
        ],
      ),
    );
    if (index == null || !mounted) return;
    _team.place(
      index,
      species,
      fastId: entry.fast.id,
      chargedIds: <String>[for (final c in entry.charged) c.id],
    );
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        persist: false,
        content: Text('${species.nameFr} ajouté à l\'emplacement ${index + 1}'),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            if (context.mounted) _openTeam(context);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _team.dispose();
    _meta.dispose();
    _collection.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_recordHistory);
    _history.dispose();
    _update.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            IvLogo(size: 34),
            SizedBox(width: 10),
            Text('ivHelper', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Paramètres',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: SettingsDrawer(
        settings: widget.settings,
        onOpenTeam: () => _openTeam(context),
        onOpenCollection: () => _openCollection(context),
        onStartOverlay: () => unawaited(_startOverlay(context)),
        onOpenSearch: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SearchStringScreen(
              repository: widget.repository,
              moves: widget.moves,
            ),
          ),
        ),
        onExportAccount: () => unawaited(_exportAccount(context)),
        onImportAccount: () => unawaited(_importAccount(context)),
        update: _update,
        gameDataUpdated: widget.gameDataUpdated,
        onOpenMeta: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MetaScreen(
              meta: _meta,
              collectionChanges: _collection,
              actions: _metaActions,
            ),
          ),
        ),
        onOpenTypes: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TypeChartScreen()),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[_controller, _update, _history]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (_update.showBanner) ...<Widget>[
                UpdateBanner(update: _update),
                const SizedBox(height: 12),
              ],
              SearchField(
                controller: _text,
                label: 'Pokémon (nom ou numéro)',
                hint: 'Flambusard ou 663',
                onChanged: _controller.setQuery,
              ),
              ..._suggestions(),
              const SizedBox(height: 12),
              _ivRow(),
              const SizedBox(height: 12),
              SegmentedButton<double>(
                segments: const <ButtonSegment<double>>[
                  ButtonSegment<double>(value: 50, label: Text('Max 50')),
                  ButtonSegment<double>(
                    value: 51,
                    label: Text('Max 51 (ami)'),
                  ),
                ],
                selected: <double>{_controller.maxLevel},
                onSelectionChanged: (selection) =>
                    _controller.setMaxLevel(selection.first),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, label: Text('Tous les IV')),
                  ButtonSegment<int>(
                    value: 10,
                    label: Text('Min 10/10/10'),
                  ),
                ],
                selected: <int>{_controller.minIv},
                onSelectionChanged: (selection) =>
                    _controller.setMinIv(selection.first),
              ),
              const SizedBox(height: 16),
              ..._results(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _suggestions() {
    if (_controller.species != null || !_controller.hasUnknownQuery) {
      return const <Widget>[];
    }
    final suggestions = _controller.suggestions;
    if (suggestions.isEmpty) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Espèce inconnue'),
        ),
      ];
    }
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: <Widget>[
            for (final s in suggestions)
              ActionChip(
                label: Text(s.nameFr),
                onPressed: () {
                  _controller.selectSpecies(s);
                  _text.text = s.nameFr;
                },
              ),
          ],
        ),
      ),
    ];
  }

  Widget _ivRow() {
    final iv = _controller.iv;
    final min = _controller.minIv;
    return Column(
      children: <Widget>[
        IvBar(
          label: 'Atk',
          value: iv.atk,
          min: min,
          onChanged: (v) => _controller.setIv(Iv(v, iv.def, iv.sta)),
        ),
        IvBar(
          label: 'Déf',
          value: iv.def,
          min: min,
          onChanged: (v) => _controller.setIv(Iv(iv.atk, v, iv.sta)),
        ),
        IvBar(
          label: 'PV',
          value: iv.sta,
          min: min,
          onChanged: (v) => _controller.setIv(Iv(iv.atk, iv.def, v)),
        ),
        const SizedBox(height: 4),
        TextField(
          key: const ValueKey<String>('quick-iv'),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Saisie rapide des IV',
            hintText: '15/14/13 ou 151413',
            prefixIcon: Icon(Icons.bolt),
            isDense: true,
          ),
          onChanged: _quickIv,
          onSubmitted: _quickIv,
        ),
      ],
    );
  }

  List<Widget> _recent() {
    final items = _history.items;
    if (items.isEmpty) return const <Widget>[];
    final theme = Theme.of(context);
    return <Widget>[
      Row(
        children: <Widget>[
          const Icon(Icons.history, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Dernières recherches', style: theme.textTheme.titleSmall),
          ),
          TextButton(onPressed: _history.clear, child: const Text('Effacer')),
        ],
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final h in items)
            if (widget.repository.findByName(h.speciesName) case final s?)
              ActionChip(
                key: ValueKey<String>('recent-${h.speciesName}'),
                avatar: s.types.isEmpty
                    ? null
                    : ExcludeSemantics(child: TypeBadge(s.types.first, size: 22)),
                label: Text(
                  '${h.speciesName} · ${h.iv.atk}/${h.iv.def}/${h.iv.sta}',
                ),
                onPressed: () => _show(s, h.iv),
              ),
        ],
      ),
    ];
  }

  List<Widget> _results(BuildContext context) {
    final species = _controller.species;
    final result = _controller.result;
    if (species == null || result == null) return _recent();
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${species.nameFr} · n° ${species.dex}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _save(context),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ResultPanel(
        species: species,
        result: result,
        onLeagueChanged: (league) => _league = league,
      ),
    ];
  }
}
