import 'package:ivhelper/settings/account_files.dart';

/// Fichiers de compte en mémoire : garde le dernier fichier enregistré et
/// renvoie [toPick] à l'ouverture.
class FakeAccountFiles implements AccountFiles {
  /// Crée le faux, avec le contenu du fichier à « choisir ».
  FakeAccountFiles({this.toPick});

  /// Contenu renvoyé par [pick] (`null` : l'utilisateur annule).
  String? toPick;

  /// Nom du dernier fichier enregistré.
  String? savedName;

  /// Contenu du dernier fichier enregistré.
  String? savedContent;

  @override
  Future<bool> save(String fileName, String content) async {
    savedName = fileName;
    savedContent = content;
    return true;
  }

  @override
  Future<String?> pick() async => toPick;
}
