package io.qonversion.sandwich

import com.qonversion.android.sdk.automations.Automations
import com.qonversion.android.sdk.automations.AutomationsDelegate
import com.qonversion.android.sdk.automations.dto.QActionResult
import com.qonversion.android.sdk.dto.QonversionError
import com.qonversion.android.sdk.listeners.QonversionShowScreenCallback

class AutomationsSandwich {

    private lateinit var automationsDelegate: AutomationsDelegate;

    // region Initialization

    fun setDelegate(eventListener: AutomationsEventListener) {
        automationsDelegate = createAutomationsDelegate(eventListener)
        Automations.shared.setDelegate(automationsDelegate)
    }

    // endregion

    // region Notifications

    fun getNotificationCustomPayload(notificationData: Map<String, Any?>): Map<String, Any?>? {
        val stringData = notificationData.toStringMap()
        return Automations.shared.getNotificationCustomPayload(stringData)
    }

    fun setNotificationToken(token: String) {
        Automations.shared.setNotificationsToken(token)
    }

    fun handleNotification(notificationData: Map<String, Any?>): Boolean {
        val stringData = notificationData.toStringMap()
        return Automations.shared.handleNotification(stringData)
    }

    // endregion

    // region Other

    fun showScreen(screenId: String, resultListener: ResultListener) {
        Automations.shared.showScreen(screenId, object : QonversionShowScreenCallback {
            override fun onSuccess() {
                resultListener.onSuccess(emptyMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        });
    }

    // endregion

    // region Private

    private fun createAutomationsDelegate(eventListener: AutomationsEventListener): AutomationsDelegate {
        return object : AutomationsDelegate {
            override fun automationsDidShowScreen(screenId: String) {
                val payload = mapOf("screenId" to screenId)
                eventListener.onAutomationEvent(AutomationsEventListener.Event.ScreenShown, payload)
            }

            override fun automationsDidStartExecuting(actionResult: QActionResult) {
                eventListener.onAutomationEvent(AutomationsEventListener.Event.ActionStarted, actionResult.toMap())
            }

            override fun automationsDidFailExecuting(actionResult: QActionResult) {
                eventListener.onAutomationEvent(AutomationsEventListener.Event.ActionFailed, actionResult.toMap())
            }

            override fun automationsDidFinishExecuting(actionResult: QActionResult) {
                eventListener.onAutomationEvent(AutomationsEventListener.Event.ActionFinished, actionResult.toMap())
            }

            override fun automationsFinished() {
                eventListener.onAutomationEvent(AutomationsEventListener.Event.AutomationsFinished)
            }
        }
    }

    // endregion
}