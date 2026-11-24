import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/species_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SpeciesRepository.load();
  runApp(IvHelperApp(repository: repository));
}
