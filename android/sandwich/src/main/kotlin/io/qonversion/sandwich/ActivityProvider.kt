package io.qonversion.sandwich

import android.app.Activity

interface ActivityProvider {

    val currentActivity: Activity?
}