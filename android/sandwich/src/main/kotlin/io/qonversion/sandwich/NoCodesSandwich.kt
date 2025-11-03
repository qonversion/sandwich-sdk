package io.qonversion.sandwich

import android.content.Context
import android.util.Log
import io.qonversion.nocodes.NoCodes
import io.qonversion.nocodes.NoCodesConfig
import io.qonversion.nocodes.dto.LogLevel
import io.qonversion.nocodes.interfaces.NoCodesDelegate
import io.qonversion.nocodes.interfaces.ScreenCustomizationDelegate
import io.qonversion.nocodes.dto.QScreenPresentationConfig
import io.qonversion.nocodes.dto.QAction
import io.qonversion.nocodes.error.NoCodesError
import androidx.core.content.edit

class NoCodesSandwich {

    private var defaultPresentationConfig: QScreenPresentationConfig? = null
    private val screenPresentationConfigs = mutableMapOf<String, QScreenPresentationConfig>()
    private var isCustomizationDelegateSet = false
    private val screenCustomizationDelegate = object : ScreenCustomizationDelegate {
        override fun getPresentationConfigurationForScreen(contextKey: String): QScreenPresentationConfig {
            return screenPresentationConfigs[contextKey] ?: defaultPresentationConfig ?: QScreenPresentationConfig()
        }
    }
    private lateinit var noCodesDelegate: NoCodesDelegate

    // region Initialization

    fun initialize(
        context: Context,
        projectKey: String,
        proxyUrl: String? = null,
        logLevelKey: String? = null,
        logTag: String? = null
    ) {
        val configBuilder = NoCodesConfig.Builder(context, projectKey)

        proxyUrl?.let {
            configBuilder.setProxyURL(it)
        }

        logLevelKey?.let {
            try {
                val logLevel = LogLevel.valueOf(it)
                configBuilder.setLogLevel(logLevel)
            } catch (e: IllegalArgumentException) {
                Log.w("No-Codes Sandwich", "Invalid log level provided: $it")
            }
        }

        logTag?.let {
            configBuilder.setLogTag(it)
        }

        NoCodes.initialize(configBuilder.build())
    }

    fun storeSdkInfo(context: Context, source: String, version: String) {
        context.getSharedPreferences(NO_CODES_PREFS_NAME, Context.MODE_PRIVATE).edit {
            putString(NO_CODES_KEY_VERSION, version)
            putString(NO_CODES_KEY_SOURCE, source)
        }
    }

    // endregion

    // region Delegate

    fun setDelegate(eventListener: NoCodesEventListener) {
        noCodesDelegate = createNoCodesDelegate(eventListener)
        NoCodes.shared.setDelegate(noCodesDelegate)
    }

    fun setScreenCustomizationDelegate() {
        if (!isCustomizationDelegateSet) {
            isCustomizationDelegateSet = true
            NoCodes.shared.setScreenCustomizationDelegate(screenCustomizationDelegate)
        }
    }

    fun setScreenPresentationConfig(configData: Map<String, Any?>, contextKey: String? = null) {
        val config = configData.toScreenPresentationConfig()

        if (!isCustomizationDelegateSet) {
            isCustomizationDelegateSet = true
            NoCodes.shared.setScreenCustomizationDelegate(screenCustomizationDelegate)
        }

        contextKey?.let {
            screenPresentationConfigs[contextKey] = config
        } ?: run {
            screenPresentationConfigs.clear()
            defaultPresentationConfig = config
        }
    }

    // endregion

    // region Screen Management

    fun showScreen(contextKey: String) {
        NoCodes.shared.showScreen(contextKey)
    }

    fun close() {
        NoCodes.shared.close()
    }

    // endregion

    // region Configuration

    fun setLogLevel(logLevelKey: String) {
        val logLevel = LogLevel.valueOf(logLevelKey)
        NoCodes.shared.setLogLevel(logLevel)
    }

    fun setLogTag(logTag: String) {
        NoCodes.shared.setLogTag(logTag)
    }

    // endregion

    // region Private

    private fun createNoCodesDelegate(eventListener: NoCodesEventListener): NoCodesDelegate {
        return object : NoCodesDelegate {
            override fun onScreenShown(screenId: String) {
                val payload = mapOf("screenId" to screenId)
                eventListener.onNoCodesEvent(NoCodesEventListener.Event.ScreenShown, payload)
            }

            override fun onActionStartedExecuting(action: QAction) {
                eventListener.onNoCodesEvent(NoCodesEventListener.Event.ActionStarted, action.toMap())
            }

            override fun onActionFailedToExecute(action: QAction) {
                eventListener.onNoCodesEvent(NoCodesEventListener.Event.ActionFailed, action.toMap())
            }

            override fun onActionFinishedExecuting(action: QAction) {
                eventListener.onNoCodesEvent(NoCodesEventListener.Event.ActionFinished, action.toMap())
            }

            override fun onFinished() {
                eventListener.onNoCodesEvent(NoCodesEventListener.Event.Finished)
            }

            override fun onScreenFailedToLoad(error: NoCodesError) {
                eventListener.onNoCodesEvent(NoCodesEventListener.Event.ScreenFailedToLoad, error.toMap())
            }
        }
    }

    // endregion
}