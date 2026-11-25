package fr.ivhelper.capture;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.Looper;


import java.io.File;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Canal « ivhelper/capture » : autorisation, capture et arrêt, et fermeture
 * de la tâche de l'appli (mise à jour).
 */
public class IvhelperCapturePlugin
        implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private static final Handler MAIN = new Handler(Looper.getMainLooper());
    private static MethodChannel.Result pendingConsent;

    private MethodChannel channel;
    private Context context;
    private Activity activity;

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "ivhelper/capture");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    /** Transmet la réponse à la demande d'autorisation en attente. */
    static void completeConsent(final boolean granted) {
        MAIN.post(() -> {
            if (pendingConsent != null) {
                pendingConsent.success(granted);
                pendingConsent = null;
            }
        });
    }

    @Override
    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
        switch (call.method) {
            case "isActive":
                result.success(CaptureService.isReady());
                break;
            case "requestCapture":
                if (CaptureService.isReady()) {
                    result.success(true);
                    return;
                }
                if (pendingConsent != null) {
                    pendingConsent.success(false);
                }
                pendingConsent = result;
                Intent intent = new Intent(context, CaptureConsentActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
                break;
            case "capture":
                final CaptureService service = CaptureService.current();
                if (service == null) {
                    result.error("NOT_READY", "Capture d'écran non autorisée", null);
                    return;
                }
                new Thread(() -> {
                    try {
                        Bitmap bitmap = service.grab();
                        File file = new File(context.getCacheDir(), "ivhelper_capture.png");
                        CaptureService.writePng(bitmap, file);
                        final Map<String, Object> map = new HashMap<>();
                        map.put("path", file.getAbsolutePath());
                        map.put("width", bitmap.getWidth());
                        map.put("height", bitmap.getHeight());
                        map.put("lines", TextReader.read(bitmap));
                        MAIN.post(() -> result.success(map));
                    } catch (final Exception e) {
                        final String message =
                                e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
                        MAIN.post(() -> result.error("CAPTURE_FAILED", message, null));
                    }
                }).start();
                break;
            case "stop":
                CaptureService.stopAll(context);
                result.success(null);
                break;
            case "closeTask":
                // L'installeur tourne dans sa propre tâche : retirer la nôtre
                // des applis récentes évite une deuxième fiche ivHelper après
                // « Ouvrir » (l'ancienne tâche, tuée par la mise à jour,
                // restait affichée).
                if (activity != null) {
                    activity.finishAndRemoveTask();
                }
                result.success(activity != null);
                break;
            default:
                result.notImplemented();
        }
    }
}
