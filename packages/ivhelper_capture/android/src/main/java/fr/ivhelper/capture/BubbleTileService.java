package fr.ivhelper.capture;

import android.annotation.SuppressLint;
import android.app.PendingIntent;
import android.content.Intent;
import android.os.Build;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

/**
 * Tuile « Pastille ivHelper » des réglages rapides : ouvre l'appli, qui lance
 * la pastille puis revient au jeu.
 */
public class BubbleTileService extends TileService {
    @Override
    public void onStartListening() {
        final Tile tile = getQsTile();
        if (tile == null) return;
        tile.setState(Tile.STATE_INACTIVE);
        tile.updateTile();
    }

    @Override
    public void onClick() {
        if (isLocked()) {
            unlockAndRun(this::launch);
        } else {
            launch();
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    @SuppressWarnings("deprecation")
    private void launch() {
        final Intent intent = IvhelperCapturePlugin.bubbleIntent(this);
        if (intent == null) return;
        if (Build.VERSION.SDK_INT >= 34) {
            // Depuis Android 14, seule la version PendingIntent est permise.
            final PendingIntent pending = PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
            startActivityAndCollapse(pending);
        } else {
            startActivityAndCollapse(intent);
        }
    }
}
