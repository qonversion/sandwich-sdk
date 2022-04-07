package io.qonversion.sandwich

interface AutomationsBridge {

    companion object {


        private var backingInstance: AutomationsBridge? = null

        @JvmStatic
        val sharedInstance: AutomationsBridge
            get() = backingInstance ?: throw IllegalStateException("Access to non-initialized instance")

        @JvmStatic
        fun initialize(): AutomationsBridge {
            return AutomationsBridgeImpl().also {
                backingInstance = it
            }
        }
    }

    fun subscribe(eventListener: AutomationsEventListener)
}
