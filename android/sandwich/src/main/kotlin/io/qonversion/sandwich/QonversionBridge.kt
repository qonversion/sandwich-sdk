package io.qonversion.sandwich

import android.app.Application

interface QonversionBridge {

    companion object {

        private var backingInstance: QonversionBridge? = null

        @JvmStatic
        val sharedInstance: QonversionBridge
            get() = backingInstance ?: throw IllegalStateException("Access to non-initialized instance")

        @JvmStatic
        fun initialize(
            application: Application,
            activityProvider: ActivityProvider,
            asyncEventsListener: AsyncEventsListener
        ): QonversionBridge {
            return QonversionBridgeImpl(application, activityProvider, asyncEventsListener).also {
                backingInstance = it
            }
        }
    }

    fun storeSdkInfo(source: String, version: String)

    fun launch(projectKey: String, isObserveMode: Boolean, resultListener: ResultListener)

    fun identify(userId: String)

    fun purchase(productId: String, resultListener: ResultListener)

    fun purchaseProduct(productId: String, offeringId: String?, resultListener: ResultListener)

    fun updatePurchase(
        productId: String,
        oldProductId: String,
        prorationMode: Int?,
        resultListener: ResultListener
    )

    fun updatePurchase(productId: String, oldProductId: String, resultListener: ResultListener) =
        updatePurchase(productId, oldProductId, null, resultListener)

    fun updatePurchaseWithProduct(
        productId: String,
        offeringId: String?,
        oldProductId: String,
        prorationMode: Int?,
        resultListener: ResultListener
    )

    fun updatePurchaseWithProduct(
        productId: String,
        offeringId: String?,
        oldProductId: String,
        resultListener: ResultListener
    ) = updatePurchaseWithProduct(productId, offeringId, oldProductId, null, resultListener)

    fun checkPermissions(resultListener: ResultListener)

    fun restore(resultListener: ResultListener)

    fun offerings(resultListener: ResultListener)

    fun products(resultListener: ResultListener)

    fun setDefinedProperty(propertyKey: String, value: String)

    fun setCustomProperty(key: String, value: String)

    fun syncPurchases()

    fun logout()

    fun setDebugMode()

    @Deprecated(
        "This function was used in debug mode only. You can reinstall the app if you need to reset the user ID.",
        level = DeprecationLevel.WARNING
    )
    fun resetUser()

    fun addAttributionData(sourceKey: String, data: Map<String, Any>)

    fun checkTrialIntroEligibility(ids: List<String>, resultListener: ResultListener)

    fun experiments(resultListener: ResultListener)

    fun setNotificationToken(token: String)

    fun handleNotification(notificationData: Map<String, Any?>): Boolean
}
