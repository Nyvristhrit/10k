package com.bquillere.tenk

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * L'écran unique de l'appli (Flutter). En plus, il change l'icône du
 * lanceur selon le mode trash : deux « alias » de cet écran sont déclarés
 * dans AndroidManifest.xml, l'un avec l'icône classique (`.MainActivity`),
 * l'autre avec l'icône néon (`.TrashLauncher`), et on n'en laisse qu'un
 * d'actif. Voir DECISIONS A-014.
 *
 * Côté Flutter, `AppIcon.sync` envoie l'icône voulue sur le canal
 * `tenk/app_icon`. La bascule n'est faite qu'en **quittant** l'appli
 * (`onStop`) : changer d'alias pendant qu'on est dedans peut la faire se
 * fermer sur certains téléphones.
 */
class TenkActivity : FlutterActivity() {
    /** Icône demandée par Flutter (`null` : rien demandé, on ne touche à rien). */
    private var wantTrashIcon: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tenk/app_icon")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setTrashIcon" -> {
                        wantTrashIcon = call.arguments as? Boolean
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStop() {
        super.onStop()
        wantTrashIcon?.let { applyIcon(it) }
    }

    private fun applyIcon(trash: Boolean) {
        val classic = ComponentName(packageName, "$packageName.MainActivity")
        val neon = ComponentName(packageName, "$packageName.TrashLauncher")
        try {
            // Déjà la bonne icône : surtout ne rien toucher (chaque bascule
            // fait se rafraîchir le lanceur).
            if (isEnabled(neon, byDefault = false) == trash &&
                isEnabled(classic, byDefault = true) != trash
            ) return
            val (on, off) = if (trash) neon to classic else classic to neon
            // D'abord activer la nouvelle entrée, puis éteindre l'ancienne :
            // l'appli n'est jamais sans icône dans le lanceur.
            setEnabled(on, true)
            setEnabled(off, false)
        } catch (_: Exception) {
            // Lanceur ou système récalcitrant : on garde l'icône actuelle.
        }
    }

    /** État effectif d'une entrée ; [byDefault] = valeur du manifeste. */
    private fun isEnabled(component: ComponentName, byDefault: Boolean): Boolean =
        when (packageManager.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> byDefault
            else -> false
        }

    private fun setEnabled(component: ComponentName, enabled: Boolean) {
        val wanted = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        packageManager.setComponentEnabledSetting(
            component, wanted, PackageManager.DONT_KILL_APP,
        )
    }
}
