package io.qonversion.sandwich

interface NoCodesEventListener {
    fun onNoCodesEvent(event: Event, payload: BridgeData? = null)
    
    enum class Event(val key: String) {
        ScreenShown("nocodes_screen_shown"),
        Finished("nocodes_finished"),
        ActionStarted("nocodes_action_started"),
        ActionFinished("nocodes_action_finished"),
        ActionFailed("nocodes_action_failed"),
        ScreenFailedToLoad("nocodes_screen_failed_to_load")
    }
} 