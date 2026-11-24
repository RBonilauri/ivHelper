package fr.ivhelper.capture;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.Image;
import android.media.ImageReader;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.util.DisplayMetrics;
import android.view.WindowManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

/**
 * Service de premier plan qui garde une session MediaProjection ouverte et la
 * dernière image de l'écran, pour la capturer à la demande.
 */
public class CaptureService extends Service {
    static final String EXTRA_CODE = "code";
    static final String EXTRA_DATA = "data";
    private static final String ACTION_STOP = "fr.ivhelper.capture.STOP";
    private static final String CHANNEL_ID = "ivhelper_capture";
    private static final int NOTIFICATION_ID = 4710;
    private static final String OVERLAY_SERVICE =
            "flutter.overlay.window.flutter_overlay_window.OverlayService";

    private static volatile CaptureService instance;

    private final Object lock = new Object();
    private MediaProjection projection;
    private VirtualDisplay display;
    private ImageReader reader;
    private Image latest;
    private HandlerThread thread;
    private int width;
    private int height;
    private boolean released;

    static boolean isReady() {
        return instance != null;
    }

    static CaptureService current() {
        return instance;
    }

    /** Arrête la capture et la pastille. */
    static void stopAll(Context context) {
        CaptureService service = instance;
        if (service != null) {
            service.release();
            service.stopForeground(true);
            service.stopSelf();
        }
        Intent overlay = new Intent();
        overlay.setClassName(context.getPackageName(), OVERLAY_SERVICE);
        try {
            context.stopService(overlay);
        } catch (Exception ignored) {
            // La pastille n'était pas lancée.
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            stopAll(this);
            return START_NOT_STICKY;
        }
        startInForeground();
        if (intent == null) {
            IvhelperCapturePlugin.completeConsent(false);
            stopSelf();
            return START_NOT_STICKY;
        }
        int code = intent.getIntExtra(EXTRA_CODE, 0);
        Intent data;
        if (Build.VERSION.SDK_INT >= 33) {
            data = intent.getParcelableExtra(EXTRA_DATA, Intent.class);
        } else {
            data = intent.getParcelableExtra(EXTRA_DATA);
        }
        MediaProjectionManager manager =
                (MediaProjectionManager) getSystemService(MEDIA_PROJECTION_SERVICE);
        projection = data == null ? null : manager.getMediaProjection(code, data);
        if (projection == null) {
            IvhelperCapturePlugin.completeConsent(false);
            stopSelf();
            return START_NOT_STICKY;
        }
        thread = new HandlerThread("ivhelper-capture");
        thread.start();
        Handler handler = new Handler(thread.getLooper());
        projection.registerCallback(
                new MediaProjection.Callback() {
                    @Override
                    public void onStop() {
                        release();
                    }
                },
                handler);

        DisplayMetrics metrics = new DisplayMetrics();
        WindowManager wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        wm.getDefaultDisplay().getRealMetrics(metrics);
        width = metrics.widthPixels;
        height = metrics.heightPixels;
        reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 3);
        reader.setOnImageAvailableListener(
                r -> {
                    Image image;
                    try {
                        image = r.acquireLatestImage();
                    } catch (IllegalStateException e) {
                        return;
                    }
                    if (image == null) {
                        return;
                    }
                    synchronized (lock) {
                        if (latest != null) {
                            latest.close();
                        }
                        latest = image;
                    }
                },
                handler);
        display =
                projection.createVirtualDisplay(
                        "ivhelper-capture",
                        width,
                        height,
                        metrics.densityDpi,
                        DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                        reader.getSurface(),
                        null,
                        handler);
        instance = this;
        IvhelperCapturePlugin.completeConsent(true);
        return START_NOT_STICKY;
    }

    /** Écrit la dernière image de l'écran dans [file] et renvoie sa taille. */
    int[] grabToFile(File file) throws IOException {
        Bitmap bitmap;
        synchronized (lock) {
            if (latest == null) {
                throw new IOException("Aucune image de l'écran pour l'instant");
            }
            Image.Plane plane = latest.getPlanes()[0];
            ByteBuffer buffer = plane.getBuffer();
            int pixelStride = plane.getPixelStride();
            int rowStride = plane.getRowStride();
            int paddedWidth = rowStride / pixelStride;
            Bitmap padded = Bitmap.createBitmap(paddedWidth, height, Bitmap.Config.ARGB_8888);
            buffer.rewind();
            padded.copyPixelsFromBuffer(buffer);
            bitmap = paddedWidth == width ? padded : Bitmap.createBitmap(padded, 0, 0, width, height);
        }
        // L'écran est opaque : certains téléphones livrent un alpha nul, qui
        // effacerait l'image une fois décodée.
        bitmap.setHasAlpha(false);
        boolean written;
        try (FileOutputStream out = new FileOutputStream(file)) {
            written = bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
        }
        if (!written || file.length() == 0) {
            throw new IOException("Enregistrement de la capture impossible");
        }
        return new int[] {width, height};
    }

    private void startInForeground() {
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel =
                    new NotificationChannel(
                            CHANNEL_ID, "Lecture d'écran ivHelper", NotificationManager.IMPORTANCE_LOW);
            nm.createNotificationChannel(channel);
            builder = new Notification.Builder(this, CHANNEL_ID);
        } else {
            builder = new Notification.Builder(this);
        }
        Intent stop = new Intent(this, CaptureService.class).setAction(ACTION_STOP);
        PendingIntent stopIntent =
                PendingIntent.getService(
                        this,
                        0,
                        stop,
                        PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        Notification notification =
                builder.setContentTitle("ivHelper : lecture d'écran active")
                        .setContentText("Touche la pastille sur la fiche d'un Pokémon.")
                        .setSmallIcon(getApplicationInfo().icon)
                        .setOngoing(true)
                        .addAction(
                                new Notification.Action.Builder(
                                                null, "Arrêter", stopIntent)
                                        .build())
                        .build();
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(
                    NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION);
        } else {
            startForeground(NOTIFICATION_ID, notification);
        }
    }

    private void release() {
        synchronized (lock) {
            if (released) {
                return;
            }
            released = true;
            instance = null;
            if (latest != null) {
                latest.close();
                latest = null;
            }
        }
        if (display != null) {
            display.release();
        }
        if (reader != null) {
            reader.close();
        }
        if (projection != null) {
            try {
                projection.stop();
            } catch (Exception ignored) {
                // Déjà arrêtée.
            }
        }
        if (thread != null) {
            thread.quitSafely();
        }
    }

    @Override
    public void onDestroy() {
        release();
        super.onDestroy();
    }
}
