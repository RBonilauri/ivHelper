import 'package:material_ui/material_ui.dart';

import 'core/species_repository.dart';
import 'ui/home_screen.dart';

/// Application ivHelper : rang PvP des IV en ligue super et hyper.
class IvHelperApp extends StatelessWidget {
  /// Crée l'application à partir du [repository] d'espèces.
  const IvHelperApp({super.key, required this.repository});

  /// Espèces connues.
  final SpeciesRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ivHelper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}
