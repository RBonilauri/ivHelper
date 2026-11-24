import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/overlay/overlay_services.dart';
import 'package:ivhelper_capture/ivhelper_capture.dart';

void main() {
  test('la capture renvoie aussi les lignes lues par ML Kit côté Android', () {
    final shot = CapturedScreen.fromMap(<Object?, Object?>{
      'path': '/cache/ivhelper_capture.png',
      'width': 1160,
      'height': 2576,
      'lines': <Object?>[
        <Object?, Object?>{
          'text': 'Attaque',
          'left': 138,
          'top': 1880,
          'right': 275,
          'bottom': 1915,
        },
      ],
    });

    expect(shot.path, '/cache/ivhelper_capture.png');
    expect(shot.width, 1160);
    expect(shot.height, 2576);
    expect(shot.lines, hasLength(1));
    final line = ocrLinesOf(shot).single;
    expect(line.text, 'Attaque');
    expect(
      [line.left, line.top, line.right, line.bottom],
      [138.0, 1880.0, 275.0, 1915.0],
    );
  });

  test('une capture sans texte lu donne une liste vide', () {
    final shot = CapturedScreen.fromMap(<Object?, Object?>{
      'path': '/cache/ivhelper_capture.png',
      'width': 10,
      'height': 20,
    });

    expect(ocrLinesOf(shot), isEmpty);
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
