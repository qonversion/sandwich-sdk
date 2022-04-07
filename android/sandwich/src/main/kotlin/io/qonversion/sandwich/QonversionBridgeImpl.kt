package io.qonversion.sandwich

import android.app.Application
import androidx.preference.PreferenceManager
import com.qonversion.android.sdk.*
import com.qonversion.android.sdk.dto.QLaunchResult
import com.qonversion.android.sdk.dto.QPermission
import com.qonversion.android.sdk.dto.eligibility.QEligibility
import com.qonversion.android.sdk.dto.experiments.QExperimentInfo
import com.qonversion.android.sdk.dto.offerings.QOfferings
import com.qonversion.android.sdk.dto.products.QProduct

class QonversionBridgeImpl internal constructor(
    private val application: Application,
    private val activityProvider: ActivityProvider,
    private val asyncEventsListener: AsyncEventsListener
) : QonversionBridge {

    private var isSubscribedOnAsyncEvents = false

    private val noActivityForPurchaseErrorMap = QonversionError(
        QonversionErrorCode.PurchaseInvalid,
        "Current Android activity is null, cannot perform the action."
    ).toMap()

    override fun storeSdkInfo(source: String, version: String) {
        val editor = PreferenceManager.getDefaultSharedPreferences(application).edit()
        editor.putString(KEY_VERSION, version)
        editor.putString(KEY_SOURCE, source)
        editor.apply()
    }

    override fun launch(
        projectKey: String,
        isObserveMode: Boolean,
        resultListener: ResultListener
    ) {
        Qonversion.launch(
            application,
            projectKey,
            isObserveMode,
            callback = object : QonversionLaunchCallback {
                override fun onSuccess(launchResult: QLaunchResult) {
                    resultListener.onSuccess(launchResult.toMap())
                }

                override fun onError(error: QonversionError) {
                    resultListener.onError(error.toMap())
                }
            }
        )

        subscribeOnAsyncEvents()
    }

    override fun identify(userId: String) {
        Qonversion.identify(userId)
    }

    override fun purchase(productId: String, resultListener: ResultListener) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseErrorMap)
                return
            }

        val permissionsCallback = getPermissionsCallback(resultListener)
        Qonversion.purchase(currentActivity, productId, permissionsCallback)
    }

    override fun purchaseProduct(
        productId: String,
        offeringId: String?,
        resultListener: ResultListener
    ) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseErrorMap)
                return
            }

        val permissionsCallback = getPermissionsCallback(resultListener)
        loadProduct(productId, offeringId, object : ProductCallback {
            override fun onProductLoaded(product: QProduct) {
                Qonversion.purchase(currentActivity, product, permissionsCallback)
            }

            override fun onLoadingFailed() {
                purchase(productId, resultListener)
            }
        })
    }

    override fun updatePurchase(
        productId: String,
        oldProductId: String,
        prorationMode: Int?,
        resultListener: ResultListener
    ) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseErrorMap)
                return
            }

        val permissionsCallback = getPermissionsCallback(resultListener)
        Qonversion.updatePurchase(currentActivity, productId, oldProductId, prorationMode, permissionsCallback)
    }

    override fun updatePurchaseWithProduct(
        productId: String,
        offeringId: String?,
        oldProductId: String,
        prorationMode: Int?,
        resultListener: ResultListener
    ) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseErrorMap)
                return
            }

        val permissionsCallback = getPermissionsCallback(resultListener)
        loadProduct(productId, offeringId, object : ProductCallback {
            override fun onProductLoaded(product: QProduct) {
                Qonversion.updatePurchase(currentActivity, product, oldProductId, prorationMode, permissionsCallback)
            }

            override fun onLoadingFailed() {
                updatePurchase(productId, oldProductId, prorationMode, resultListener)
            }
        })
    }

    private interface ProductCallback {
        fun onProductLoaded(product: QProduct)

        fun onLoadingFailed()
    }

    private fun loadProduct(
        productId: String,
        offeringId: String?,
        callback: ProductCallback
    ) {
        if (offeringId == null) {
            callback.onLoadingFailed()
            return
        }
        Qonversion.offerings(object : QonversionOfferingsCallback {
            override fun onSuccess(offerings: QOfferings) {
                val offering = offerings.offeringForID(offeringId)
                if (offering == null) {
                    callback.onLoadingFailed()
                    return
                }
                val product = offering.productForID(productId)
                if (product == null) {
                    callback.onLoadingFailed()
                } else {
                    callback.onProductLoaded(product)
                }
            }

            override fun onError(error: QonversionError) {
                callback.onLoadingFailed()
            }
        })
    }

    override fun checkPermissions(resultListener: ResultListener) {
        val permissionsCallback = getPermissionsCallback(resultListener)
        Qonversion.checkPermissions(permissionsCallback)
    }

    override fun restore(resultListener: ResultListener) {
        val permissionsCallback = getPermissionsCallback(resultListener)
        Qonversion.checkPermissions(permissionsCallback)
    }

    override fun offerings(resultListener: ResultListener) {
        Qonversion.offerings(object : QonversionOfferingsCallback {
            override fun onSuccess(offerings: QOfferings) {
                resultListener.onSuccess(offerings.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toMap())
            }
        })
    }

    override fun products(resultListener: ResultListener) {
        Qonversion.products(object : QonversionProductsCallback {
            override fun onSuccess(products: Map<String, QProduct>) {
                resultListener.onSuccess(products.toProductsMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toMap())
            }
        })
    }

    override fun setDefinedProperty(propertyKey: String, value: String) {
        try {
            val property = QUserProperties.valueOf(propertyKey)
            Qonversion.setProperty(property, value)
        } catch (e: IllegalArgumentException) {
            // Ignore property.
        }
    }

    override fun setCustomProperty(key: String, value: String) {
        Qonversion.setUserProperty(key, value)
    }

    override fun syncPurchases() {
        Qonversion.syncPurchases()
    }

    override fun logout() {
        Qonversion.logout()
    }

    override fun setDebugMode() {
        Qonversion.setDebugMode()
    }

    override fun resetUser() {
        Qonversion.resetUser()
    }

    override fun addAttributionData(sourceKey: String, data: Map<String, Any>) {
        try {
            val source = AttributionSource.valueOf(sourceKey)
            Qonversion.attribution(data, source)
        } catch (e: java.lang.IllegalArgumentException) {
            // Ignore attribution.
        }
    }

    override fun checkTrialIntroEligibility(ids: List<String>, resultListener: ResultListener) {
        Qonversion.checkTrialIntroEligibilityForProductIds(ids, object : QonversionEligibilityCallback {
            override fun onSuccess(eligibilities: Map<String, QEligibility>) {
                resultListener.onSuccess(eligibilities.toEligibilityMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toMap())
            }
        })
    }

    override fun experiments(resultListener: ResultListener) {
        Qonversion.experiments(object : QonversionExperimentsCallback {
            override fun onSuccess(experiments: Map<String, QExperimentInfo>) {
                resultListener.onSuccess(experiments.toExperimentsMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toMap())
            }
        })
    }

    override fun setNotificationToken(token: String) {
        Qonversion.setNotificationsToken(token)
    }

    override fun handleNotification(notificationData: Map<String, Any?>): Boolean {
        val stringData = notificationData
            .filterValues { it != null }
            .mapValues { it.value.toString() }
        return Qonversion.handleNotification(stringData)
    }

    private fun subscribeOnAsyncEvents() {
        if (isSubscribedOnAsyncEvents) {
            return
        }

        Qonversion.setUpdatedPurchasesListener(object : UpdatedPurchasesListener {
            override fun onPermissionsUpdate(permissions: Map<String, QPermission>) {
                asyncEventsListener.onPermissionsUpdateAfterAsyncPurchase(permissions.toPermissionsMap())
            }
        })

        isSubscribedOnAsyncEvents = true
    }

    private fun getPermissionsCallback(resultListener: ResultListener) = object : QonversionPermissionsCallback {
        override fun onSuccess(permissions: Map<String, QPermission>) {
            resultListener.onSuccess(permissions.toPermissionsMap())
        }

        override fun onError(error: QonversionError) {
            resultListener.onError(error.toMap())
        }
    }
}