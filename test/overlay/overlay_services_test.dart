import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ivhelper/core/screen_reading.dart';
import 'package:ivhelper/overlay/overlay_services.dart';

void main() {
  test('la reconnaissance de texte reçoit les pixels, pas un fichier', () {
    final bytes = Uint8List(2 * 3 * 4);
    final input = ocrInputFor(RgbaImage(2, 3, bytes));

    expect(input.type, InputImageType.bitmap);
    expect(input.filePath, isNull);
    expect(input.bitmapData, same(bytes));
    expect(input.metadata!.size, const Size(2, 3));
  });

  test("le message d'erreur de lecture n'affiche pas la pile Java", () {
    final message = describeScanError(
      PlatformException(
        code: 'error',
        message: 'Attempt to invoke virtual method on a null object reference',
        details: 'java.lang.NullPointerException\n at lf1.<init>(…)\n at vf1.a(…)',
      ),
    );

    expect(
      message,
      'Lecture impossible : Attempt to invoke virtual method on a null object '
      'reference',
    );
  });

  test('une erreur de capture garde son message en français', () {
    final message = describeScanError(
      PlatformException(
        code: 'CAPTURE_FAILED',
        message: "Aucune image de l'écran pour l'instant",
      ),
    );

    expect(message, "Lecture impossible : Aucune image de l'écran pour l'instant");
  });
}
