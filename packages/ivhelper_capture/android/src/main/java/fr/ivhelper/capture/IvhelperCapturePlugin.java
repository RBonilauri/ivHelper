package fr.ivhelper.capture;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ShortcutInfo;
import android.content.pm.ShortcutManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import java.io.File;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Canal « ivhelper/capture » : autorisation, capture et arrêt, fermeture de
 * la tâche de l'appli (mise à jour), et lancements rapides de la pastille
 * (raccourci de l'icône, tuile des réglages rapides).
 */
public class IvhelperCapturePlugin
        implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
        PluginRegistry.NewIntentListener {
    /** Extra de l'intent qui ouvre l'appli pour un lancement rapide. */
    static final String EXTRA_ACTION = "fr.ivhelper.capture.ACTION";

    /** Lancement rapide de la pastille. */
    static final String ACTION_BUBBLE = "bubble";

    private static final Handler MAIN = new Handler(Looper.getMainLooper());
    private static MethodChannel.Result pendingConsent;
    private static String pendingAction;

    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private ActivityPluginBinding activityBinding;

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        attach(binding);
        readAction(activity.getIntent());
        installShortcut(activity);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        detach();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        attach(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        detach();
    }

    private void attach(ActivityPluginBinding binding) {
        activityBinding = binding;
        activity = binding.getActivity();
        binding.addOnNewIntentListener(this);
    }

    private void detach() {
        if (activityBinding != null) {
            activityBinding.removeOnNewIntentListener(this);
        }
        activityBinding = null;
        activity = null;
    }

    /** L'appli, déjà ouverte (singleTask), reçoit un nouveau lancement. */
    @Override
    public boolean onNewIntent(Intent intent) {
        if (!readAction(intent)) return false;
        // Prévient le Dart, qui lit la demande avec « takeLaunchAction ».
        if (channel != null) channel.invokeMethod("launchActionAvailable", null);
        return true;
    }

    /** Garde la demande de lancement rapide de [intent] ; vrai s'il y en a une. */
    private static boolean readAction(Intent intent) {
        if (intent == null) return false;
        final String action = intent.getStringExtra(EXTRA_ACTION);
        if (action == null) return false;
        // Retirée pour qu'une recréation de l'activité ne la rejoue pas.
        intent.removeExtra(EXTRA_ACTION);
        pendingAction = action;
        return true;
    }

    /** Intent qui ouvre l'appli et demande la pastille. */
    static Intent bubbleIntent(Context context) {
        Intent intent = context.getPackageManager()
                .getLaunchIntentForPackage(context.getPackageName());
        if (intent == null) return null;
        intent.putExtra(EXTRA_ACTION, ACTION_BUBBLE);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return intent;
    }

    /** Raccourci « Lancer la pastille » (appui long sur l'icône). */
    private static void installShortcut(Activity activity) {
        if (Build.VERSION.SDK_INT < 25) return;
        try {
            final ShortcutManager manager = activity.getSystemService(ShortcutManager.class);
            final Intent intent = bubbleIntent(activity);
            if (manager == null || intent == null) return;
            final ShortcutInfo info = new ShortcutInfo.Builder(activity, "bubble")
                    .setShortLabel("Pastille")
                    .setLongLabel("Lancer la pastille")
                    .setIcon(Icon.createWithResource(activity, R.drawable.ivhelper_bubble))
                    .setIntent(intent)
                    .build();
            manager.setDynamicShortcuts(Collections.singletonList(info));
        } catch (RuntimeException e) {
            // Lanceur sans raccourcis ou limite atteinte : rien de grave.
        }
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
            case "copyText":
                // La pastille tourne dans un moteur Flutter sans activité :
                // le canal « flutter/platform » (Clipboard.setData) n'y a pas
                // de gestionnaire et l'appel était ignoré. On écrit donc
                // directement dans le presse-papiers d'Android.
                final String text = call.argument("text");
                final ClipboardManager clipboard =
                        (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
                if (clipboard == null || text == null) {
                    result.success(false);
                    return;
                }
                clipboard.setPrimaryClip(ClipData.newPlainText("ivHelper", text));
                result.success(true);
                break;
            case "stop":
                CaptureService.stopAll(context);
                result.success(null);
                break;
            case "takeLaunchAction":
                result.success(pendingAction);
                pendingAction = null;
                break;
            case "moveToBack":
                if (activity != null) {
                    activity.moveTaskToBack(true);
                }
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
