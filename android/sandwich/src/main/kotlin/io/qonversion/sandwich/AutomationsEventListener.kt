package io.qonversion.sandwich

interface AutomationsEventListener {

    fun onAutomationEvent(event: Event, payload: BridgeData? = null)
    
    enum class Event(key: String) {
        ScreenShown("automations_screen_shown"),
        ActionStarted("automations_action_started"),
        ActionFailed("automations_action_failed"),
        ActionFinished("automations_action_finished"),
        AutomationsFinished("automations_finished")
    }
}
