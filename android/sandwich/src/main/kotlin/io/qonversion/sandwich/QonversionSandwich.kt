package io.qonversion.sandwich

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.preference.PreferenceManager
import com.qonversion.android.sdk.Qonversion
import com.qonversion.android.sdk.QonversionConfig
import com.qonversion.android.sdk.dto.QAttributionSource
import com.qonversion.android.sdk.dto.QEntitlement
import com.qonversion.android.sdk.dto.QEntitlementsCacheLifetime
import com.qonversion.android.sdk.dto.QEnvironment
import com.qonversion.android.sdk.dto.QLaunchMode
import com.qonversion.android.sdk.dto.QUser
import com.qonversion.android.sdk.dto.QUserProperties
import com.qonversion.android.sdk.dto.QonversionError
import com.qonversion.android.sdk.dto.QonversionErrorCode
import com.qonversion.android.sdk.dto.eligibility.QEligibility
import com.qonversion.android.sdk.dto.offerings.QOfferings
import com.qonversion.android.sdk.dto.products.QProduct
import com.qonversion.android.sdk.listeners.EntitlementsUpdateListener
import com.qonversion.android.sdk.listeners.QonversionEligibilityCallback
import com.qonversion.android.sdk.listeners.QonversionEntitlementsCallback
import com.qonversion.android.sdk.listeners.QonversionOfferingsCallback
import com.qonversion.android.sdk.listeners.QonversionProductsCallback
import com.qonversion.android.sdk.listeners.QonversionUserCallback

private const val TAG = "Qonversion"

class QonversionSandwich(
    private val application: Application,
    private val activityProvider: ActivityProvider,
    private val qonversionEventsListener: QonversionEventsListener
) {

    private var isSubscribedOnAsyncEvents = false

    private val noActivityForPurchaseError = QonversionError(
        QonversionErrorCode.PurchaseInvalid,
        "Current Android activity is null, cannot perform the action."
    )

    // region Initialization

    fun initialize(
        context: Context,
        projectKey: String,
        launchModeKey: String,
        environmentKey: String,
        entitlementsCacheLifetimeKey: String
    ) {
        val launchMode = QLaunchMode.valueOf(launchModeKey)
        val config = QonversionConfig.Builder(context, projectKey, launchMode)
            .setEnvironment(environmentKey)
            .setEntitlementsCacheLifetime(entitlementsCacheLifetimeKey)
            .setEntitlementsUpdateListener()
            .build()

        Qonversion.initialize(config)
    }

    fun storeSdkInfo(source: String, version: String) {
        val editor = PreferenceManager.getDefaultSharedPreferences(application).edit()
        editor.putString(KEY_VERSION, version)
        editor.putString(KEY_SOURCE, source)
        editor.apply()
    }

    // endregion

    // region Product Center

    fun purchase(productId: String, resultListener: PurchaseResultListener) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseError.toSandwichError(), false)
                return
            }

        val purchaseCallback = getPurchaseCallback(resultListener)
        Qonversion.sharedInstance.purchase(currentActivity, productId, purchaseCallback)
    }

    fun purchaseProduct(
        productId: String,
        offeringId: String?,
        resultListener: PurchaseResultListener
    ) {
        val purchaseCallback = getPurchaseCallback(resultListener)
        loadProduct(productId, offeringId, object : ProductCallback {
            override fun onProductLoaded(product: QProduct) {
                val currentActivity = activityProvider.currentActivity
                    ?: run {
                        resultListener.onError(noActivityForPurchaseError.toSandwichError(), false)
                        return
                    }

                Qonversion.sharedInstance.purchase(currentActivity, product, purchaseCallback)
            }

            override fun onLoadingFailed() {
                purchase(productId, resultListener)
            }
        })
    }

    fun updatePurchase(
        productId: String,
        oldProductId: String,
        prorationMode: Int?,
        resultListener: PurchaseResultListener
    ) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseError.toSandwichError(), false)
                return
            }

        val purchaseCallback = getPurchaseCallback(resultListener)
        Qonversion.sharedInstance.updatePurchase(
            currentActivity,
            productId,
            oldProductId,
            prorationMode,
            purchaseCallback
        )
    }

    fun updatePurchaseWithProduct(
        productId: String,
        offeringId: String?,
        oldProductId: String,
        prorationMode: Int?,
        resultListener: PurchaseResultListener
    ) {
        val purchaseCallback = getPurchaseCallback(resultListener)
        loadProduct(productId, offeringId, object : ProductCallback {
            override fun onProductLoaded(product: QProduct) {
                val currentActivity = activityProvider.currentActivity
                    ?: run {
                        resultListener.onError(noActivityForPurchaseError.toSandwichError(), false)
                        return
                    }
                Qonversion.sharedInstance.updatePurchase(
                    currentActivity,
                    product,
                    oldProductId,
                    prorationMode,
                    purchaseCallback
                )
            }

            override fun onLoadingFailed() {
                updatePurchase(productId, oldProductId, prorationMode, resultListener)
            }
        })
    }

    fun checkEntitlements(resultListener: ResultListener) {
        val entitlementsCallback = getEntitlementsCallback(resultListener)
        Qonversion.sharedInstance.checkEntitlements(entitlementsCallback)
    }

    fun offerings(resultListener: ResultListener) {
        Qonversion.sharedInstance.offerings(object : QonversionOfferingsCallback {
            override fun onSuccess(offerings: QOfferings) {
                resultListener.onSuccess(offerings.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun products(resultListener: ResultListener) {
        Qonversion.sharedInstance.products(object : QonversionProductsCallback {
            override fun onSuccess(products: Map<String, QProduct>) {
                resultListener.onSuccess(products.toProductsMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun restore(resultListener: ResultListener) {
        val entitlementsCallback = getEntitlementsCallback(resultListener)
        Qonversion.sharedInstance.restore(entitlementsCallback)
    }

    fun syncPurchases() {
        Qonversion.sharedInstance.syncPurchases()
    }

    fun checkTrialIntroEligibility(ids: List<String>, resultListener: ResultListener) {
        Qonversion.sharedInstance.checkTrialIntroEligibilityForProductIds(
            ids,
            object : QonversionEligibilityCallback {
                override fun onSuccess(eligibilities: Map<String, QEligibility>) {
                    resultListener.onSuccess(eligibilities.toEligibilityMap())
                }

                override fun onError(error: QonversionError) {
                    resultListener.onError(error.toSandwichError())
                }
            }
        )
    }

    // endregion

    // region User Info

    fun userInfo(resultListener: ResultListener) {
        Qonversion.sharedInstance.userInfo(object : QonversionUserCallback {
            override fun onSuccess(user: QUser) {
                resultListener.onSuccess(user.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun identify(userId: String) {
        Qonversion.sharedInstance.identify(userId)
    }

    fun setDefinedProperty(propertyKey: String, value: String) {
        try {
            val property = QUserProperties.valueOf(propertyKey)
            Qonversion.sharedInstance.setProperty(property, value)
        } catch (e: IllegalArgumentException) {
            // Ignore property.
        }
    }

    fun setCustomProperty(key: String, value: String) {
        Qonversion.sharedInstance.setUserProperty(key, value)
    }

    fun logout() {
        Qonversion.sharedInstance.logout()
    }

    fun addAttributionData(sourceKey: String, data: Map<String, Any>) {
        try {
            val source = QAttributionSource.valueOf(sourceKey)
            Qonversion.sharedInstance.attribution(data, source)
        } catch (e: java.lang.IllegalArgumentException) {
            // Ignore attribution.
        }
    }

    // endregion

    // region Private

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
        Qonversion.sharedInstance.offerings(object : QonversionOfferingsCallback {
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

    private fun QonversionConfig.Builder.setEnvironment(environmentKey: String) = apply {
        try {
            val environment = QEnvironment.valueOf(environmentKey)
            setEnvironment(environment)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "No environment found for key $environmentKey")
        }
    }

    private fun QonversionConfig.Builder.setEntitlementsCacheLifetime(lifetimeKey: String) = apply {
        try {
            val lifetime = QEntitlementsCacheLifetime.valueOf(lifetimeKey)
            setEntitlementsCacheLifetime(lifetime)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "No entitlements cache lifetime found for key $lifetimeKey")
        }
    }

    private fun QonversionConfig.Builder.setEntitlementsUpdateListener() = apply {
        setEntitlementsUpdateListener(object : EntitlementsUpdateListener {
            override fun onEntitlementsUpdated(entitlements: Map<String, QEntitlement>) {
                qonversionEventsListener.onEntitlementsUpdate(entitlements.toEntitlementsMap())
            }
        })
    }

    private fun getEntitlementsCallback(resultListener: ResultListener) =
        object : QonversionEntitlementsCallback {
            override fun onSuccess(entitlements: Map<String, QEntitlement>) {
                resultListener.onSuccess(entitlements.toEntitlementsMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        }

    private fun getPurchaseCallback(resultListener: PurchaseResultListener) =
        object : QonversionEntitlementsCallback {
            override fun onSuccess(entitlements: Map<String, QEntitlement>) {
                resultListener.onSuccess(entitlements.toEntitlementsMap())
            }

            override fun onError(error: QonversionError) {
                val isCancelled = error.code == QonversionErrorCode.CanceledPurchase
                resultListener.onError(error.toSandwichError(), isCancelled)
            }
        }

    // endregion
}