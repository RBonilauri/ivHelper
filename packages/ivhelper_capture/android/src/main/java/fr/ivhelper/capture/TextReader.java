package fr.ivhelper.capture;

import android.graphics.Bitmap;
import android.graphics.Rect;

import com.google.android.gms.tasks.Tasks;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Lecture du texte de l'écran par ML Kit, directement sur le Bitmap capturé
 * (aucun fichier à décoder).
 */
final class TextReader {
    private TextReader() {}

    /** Lignes de texte de [bitmap] avec leur cadre, à appeler hors du fil principal. */
    static List<Map<String, Object>> read(Bitmap bitmap) throws Exception {
        TextRecognizer recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
        try {
            Text text = Tasks.await(
                    recognizer.process(InputImage.fromBitmap(bitmap, 0)), 20, TimeUnit.SECONDS);
            List<Map<String, Object>> lines = new ArrayList<>();
            for (Text.TextBlock block : text.getTextBlocks()) {
                for (Text.Line line : block.getLines()) {
                    Rect box = line.getBoundingBox();
                    if (box == null) {
                        continue;
                    }
                    Map<String, Object> map = new HashMap<>();
                    map.put("text", line.getText());
                    map.put("left", box.left);
                    map.put("top", box.top);
                    map.put("right", box.right);
                    map.put("bottom", box.bottom);
                    lines.add(map);
                }
            }
            return lines;
        } finally {
            recognizer.close();
        }
    }
}
