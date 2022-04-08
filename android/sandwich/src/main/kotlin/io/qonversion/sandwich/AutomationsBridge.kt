package io.qonversion.sandwich

import com.qonversion.android.sdk.automations.Automations
import com.qonversion.android.sdk.automations.AutomationsDelegate
import com.qonversion.android.sdk.automations.QActionResult

class AutomationsBridge {

    fun subscribe(eventListener: AutomationsEventListener) {
        val delegate = createAutomationsDelegate(eventListener)
        Automations.setDelegate(delegate)
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
}