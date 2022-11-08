package io.qonversion.sandwich

import com.qonversion.android.sdk.automations.Automations
import com.qonversion.android.sdk.automations.AutomationsDelegate
import com.qonversion.android.sdk.automations.dto.QActionResult

class AutomationsSandwich {

    // region Initialization

    fun subscribe(eventListener: AutomationsEventListener) {
        val delegate = createAutomationsDelegate(eventListener)
        Automations.initialize()
        Automations.sharedInstance.setDelegate(delegate)
    }

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

    // region Notifications

    fun getNotificationCustomPayload(notificationData: Map<String, Any?>): Map<String, Any?>? {
        val stringData = notificationData.toStringMap()
        return Automations.sharedInstance.getNotificationCustomPayload(stringData)
    }

    fun setNotificationToken(token: String) {
        Automations.sharedInstance.setNotificationsToken(token)
    }

    fun handleNotification(notificationData: Map<String, Any?>): Boolean {
        val stringData = notificationData.toStringMap()
        return Automations.sharedInstance.handleNotification(stringData)
    }

    // endregion
}