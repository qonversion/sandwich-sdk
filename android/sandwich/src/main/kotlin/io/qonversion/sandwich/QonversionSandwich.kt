package io.qonversion.sandwich

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.preference.PreferenceManager
import com.qonversion.android.sdk.Qonversion
import com.qonversion.android.sdk.QonversionConfig
import com.qonversion.android.sdk.dto.QAttributionProvider
import com.qonversion.android.sdk.dto.QEntitlement
import com.qonversion.android.sdk.dto.QEntitlementsCacheLifetime
import com.qonversion.android.sdk.dto.QEnvironment
import com.qonversion.android.sdk.dto.QLaunchMode
import com.qonversion.android.sdk.dto.QUser
import com.qonversion.android.sdk.dto.QUserProperty
import com.qonversion.android.sdk.dto.QonversionError
import com.qonversion.android.sdk.dto.QonversionErrorCode
import com.qonversion.android.sdk.dto.eligibility.QEligibility
import com.qonversion.android.sdk.dto.offerings.QOfferings
import com.qonversion.android.sdk.dto.products.QProduct
import com.qonversion.android.sdk.listeners.QEntitlementsUpdateListener
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

    private val noActivityForPurchaseError = QonversionError(
        QonversionErrorCode.PurchaseInvalid,
        "Current Android activity is null, cannot perform the action."
    )

    // region Initialization

    fun initialize(
        context: Context,
        projectKey: String,
        launchModeKey: String,
        environmentKey: String? = null,
        entitlementsCacheLifetimeKey: String? = null,
        proxyUrl: String? = null
    ) {
        val launchMode = QLaunchMode.valueOf(launchModeKey)
        val configBuilder = QonversionConfig.Builder(context, projectKey, launchMode)
            .setEnvironment(environmentKey)
            .setEntitlementsCacheLifetime(entitlementsCacheLifetimeKey)
            .setEntitlementsUpdateListener()

        proxyUrl?.let {
            configBuilder.setProxyURL(it)
        }

        Qonversion.initialize(configBuilder.build())
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
        Qonversion.shared.purchase(currentActivity, productId, purchaseCallback)
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

                Qonversion.shared.purchase(currentActivity, product, purchaseCallback)
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
        Qonversion.shared.updatePurchase(
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
                Qonversion.shared.updatePurchase(
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
        Qonversion.shared.checkEntitlements(entitlementsCallback)
    }

    fun offerings(resultListener: ResultListener) {
        Qonversion.shared.offerings(object : QonversionOfferingsCallback {
            override fun onSuccess(offerings: QOfferings) {
                resultListener.onSuccess(offerings.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun products(resultListener: ResultListener) {
        Qonversion.shared.products(object : QonversionProductsCallback {
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
        Qonversion.shared.restore(entitlementsCallback)
    }

    fun syncPurchases() {
        Qonversion.shared.syncPurchases()
    }

    fun checkTrialIntroEligibility(ids: List<String>, resultListener: ResultListener) {
        Qonversion.shared.checkTrialIntroEligibility(
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
        Qonversion.shared.userInfo(object : QonversionUserCallback {
            override fun onSuccess(user: QUser) {
                resultListener.onSuccess(user.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun identify(userId: String) {
        Qonversion.shared.identify(userId)
    }

    fun setDefinedProperty(propertyKey: String, value: String) {
        try {
            val property = QUserProperty.valueOf(propertyKey)
            Qonversion.shared.setProperty(property, value)
        } catch (e: IllegalArgumentException) {
            // Ignore property.
        }
    }

    fun setCustomProperty(key: String, value: String) {
        Qonversion.shared.setUserProperty(key, value)
    }

    fun logout() {
        Qonversion.shared.logout()
    }

    fun addAttributionData(providerKey: String, data: Map<String, Any>) {
        try {
            val source = QAttributionProvider.valueOf(providerKey)
            Qonversion.shared.attribution(data, source)
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
        Qonversion.shared.offerings(object : QonversionOfferingsCallback {
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

    private fun QonversionConfig.Builder.setEnvironment(environmentKey: String?) = apply {
        environmentKey ?: return@apply
        try {
            val environment = QEnvironment.valueOf(environmentKey)
            setEnvironment(environment)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "No environment found for key $environmentKey")
        }
    }

    private fun QonversionConfig.Builder.setEntitlementsCacheLifetime(lifetimeKey: String?) = apply {
        lifetimeKey ?: return@apply
        try {
            val lifetime = QEntitlementsCacheLifetime.valueOf(lifetimeKey)
            setEntitlementsCacheLifetime(lifetime)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "No entitlements cache lifetime found for key $lifetimeKey")
        }
    }

    private fun QonversionConfig.Builder.setEntitlementsUpdateListener() = apply {
        setEntitlementsUpdateListener(object : QEntitlementsUpdateListener {
            override fun onEntitlementsUpdated(entitlements: Map<String, QEntitlement>) {
                qonversionEventsListener.onEntitlementsUpdated(entitlements.toEntitlementsMap())
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