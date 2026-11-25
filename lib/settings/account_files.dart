import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Enregistrement et ouverture du fichier de sauvegarde du compte.
abstract interface class AccountFiles {
  /// Propose d'enregistrer [content] sous [fileName] ; vrai si c'est fait,
  /// faux si l'utilisateur annule.
  Future<bool> save(String fileName, String content);

  /// Fait choisir un fichier et renvoie son texte, ou `null` si annulé.
  Future<String?> pick();
}

/// Fichiers de l'appareil, par le sélecteur du système (file_picker).
class FilePickerAccountFiles implements AccountFiles {
  /// Crée l'accès aux fichiers.
  const FilePickerAccountFiles();

  @override
  Future<bool> save(String fileName, String content) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter mon compte',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
    return path != null;
  }

  @override
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file == null) return null;
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }
}
