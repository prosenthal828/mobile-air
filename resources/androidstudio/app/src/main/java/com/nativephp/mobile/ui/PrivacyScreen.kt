package com.nativephp.mobile.ui

import android.app.Activity
import android.view.WindowManager

/**
 * Privacy screen: `FLAG_SECURE` on MainActivity's window while it is on.
 *
 * With the flag set, Android shows a blank card for the app in Recents and
 * captures the window as black in screenshots and screen recordings. Backs
 * `System::setPrivacyScreen()` (`System.SetPrivacyScreen`). iOS twin:
 * `PrivacyScreen.swift`.
 *
 * The setting lives in process memory. It survives MainActivity being
 * recreated (onCreate applies it again) but not a cold start, so an app that
 * wants it everywhere turns it on from PHP at boot.
 *
 * Only MainActivity's window carries the flag. Dialogs, system pickers and
 * activities started by plugins are separate windows and are not covered.
 */
object PrivacyScreen {

    @Volatile
    var enabled: Boolean = false
        private set

    fun set(enabled: Boolean) {
        this.enabled = enabled
        MainActivity.instance?.let { activity ->
            activity.runOnUiThread { apply(activity) }
        }
    }

    /** Main thread only. */
    fun apply(activity: Activity) {
        if (enabled) {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
