package io.qonversion.sandwich

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.preference.PreferenceManager
import com.qonversion.android.sdk.Qonversion
import com.qonversion.android.sdk.QonversionConfig
import com.qonversion.android.sdk.dto.QAttributionProvider
import com.qonversion.android.sdk.dto.QEnvironment
import com.qonversion.android.sdk.dto.QLaunchMode
import com.qonversion.android.sdk.dto.QPurchaseModel
import com.qonversion.android.sdk.dto.QPurchaseOptions
import com.qonversion.android.sdk.dto.QPurchaseUpdateModel
import com.qonversion.android.sdk.dto.QPurchaseUpdatePolicy
import com.qonversion.android.sdk.dto.QRemoteConfig
import com.qonversion.android.sdk.dto.QRemoteConfigList
import com.qonversion.android.sdk.dto.QUser
import com.qonversion.android.sdk.dto.QonversionError
import com.qonversion.android.sdk.dto.QonversionErrorCode
import com.qonversion.android.sdk.dto.eligibility.QEligibility
import com.qonversion.android.sdk.dto.entitlements.QEntitlement
import com.qonversion.android.sdk.dto.entitlements.QEntitlementsCacheLifetime
import com.qonversion.android.sdk.dto.offerings.QOfferings
import com.qonversion.android.sdk.dto.products.QProduct
import com.qonversion.android.sdk.dto.properties.QUserProperties
import com.qonversion.android.sdk.dto.properties.QUserPropertyKey
import com.qonversion.android.sdk.listeners.QEntitlementsUpdateListener
import com.qonversion.android.sdk.listeners.QonversionEligibilityCallback
import com.qonversion.android.sdk.listeners.QonversionEntitlementsCallback
import com.qonversion.android.sdk.listeners.QonversionExperimentAttachCallback
import com.qonversion.android.sdk.listeners.QonversionOfferingsCallback
import com.qonversion.android.sdk.listeners.QonversionProductsCallback
import com.qonversion.android.sdk.listeners.QonversionRemoteConfigCallback
import com.qonversion.android.sdk.listeners.QonversionRemoteConfigListCallback
import com.qonversion.android.sdk.listeners.QonversionRemoteConfigurationAttachCallback
import com.qonversion.android.sdk.listeners.QonversionUserCallback
import com.qonversion.android.sdk.listeners.QonversionUserPropertiesCallback

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
        proxyUrl: String? = null,
        kidsMode: Boolean = false
    ) {
        val launchMode = QLaunchMode.valueOf(launchModeKey)
        val configBuilder = QonversionConfig.Builder(context, projectKey, launchMode)
            .setEnvironment(environmentKey)
            .setEntitlementsCacheLifetime(entitlementsCacheLifetimeKey)
            .setEntitlementsUpdateListener()

        proxyUrl?.let {
            configBuilder.setProxyURL(it)
        }

        if (kidsMode) {
            configBuilder.enableKidsMode()
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

    // region Entitlements and Products

    fun purchase(
        productId: String,
        offerId: String?,
        applyOffer: Boolean?,
        oldProductId: String?,
        updatePolicyKey: String?,
        contextKeys: List<String>?,
        resultListener: ResultListener
    ) {
        val currentActivity = activityProvider.currentActivity
            ?: run {
                resultListener.onError(noActivityForPurchaseError.toSandwichError())
                return
            }

        val purchaseCallback = getEntitlementsCallback(resultListener)

        Qonversion.shared.products(object: QonversionProductsCallback {
            override fun onSuccess(products: Map<String, QProduct>) {
                val product = products[productId]
                val oldProduct = products[oldProductId]
                val purchaseOptions = configurePurchaseOptions(offerId, applyOffer, oldProduct, updatePolicyKey, contextKeys)

                if (product != null && oldProduct != null) {
                    Qonversion.shared.updatePurchase(currentActivity, product, purchaseOptions, purchaseCallback)
                } else if (product != null) {
                    Qonversion.shared.purchase(currentActivity, product, purchaseOptions, purchaseCallback)
                } else {
                    purchaseCallback.onError(QonversionError(QonversionErrorCode.ProductNotFound))
                }
            }

            override fun onError(error: QonversionError) {
                purchaseCallback.onError(error)
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
        Qonversion.shared.userInfo(getUserCallback(resultListener))
    }

    fun identify(userId: String, resultListener: ResultListener) {
        Qonversion.shared.identify(userId, getUserCallback(resultListener))
    }

    fun setDefinedProperty(propertyKey: String, value: String) {
        try {
            val property = QUserPropertyKey.valueOf(propertyKey)
            Qonversion.shared.setUserProperty(property, value)
        } catch (e: IllegalArgumentException) {
            // Ignore property.
        }
    }

    fun setCustomProperty(key: String, value: String) {
        Qonversion.shared.setCustomUserProperty(key, value)
    }

    fun userProperties(resultListener: ResultListener) {
        Qonversion.shared.userProperties(object : QonversionUserPropertiesCallback {
            override fun onSuccess(userProperties: QUserProperties) {
                resultListener.onSuccess(userProperties.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
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

    // region Experiments

    fun remoteConfig(contextKey: String?, resultListener: ResultListener) {
        val callback = object : QonversionRemoteConfigCallback {
            override fun onSuccess(remoteConfig: QRemoteConfig) {
                resultListener.onSuccess(remoteConfig.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        }
        contextKey?.let {
            Qonversion.shared.remoteConfig(it, callback)
        } ?: run {
            Qonversion.shared.remoteConfig(callback)
        }
    }

    fun remoteConfigList(contextKeys: List<String>, includeEmptyContextKey: Boolean, resultListener: ResultListener) {
        val callback = object : QonversionRemoteConfigListCallback {
            override fun onSuccess(remoteConfigList: QRemoteConfigList) {
                resultListener.onSuccess(remoteConfigList.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        }

        Qonversion.shared.remoteConfigList(contextKeys, includeEmptyContextKey, callback)
    }

    fun remoteConfigList(resultListener: ResultListener) {
        val callback = object : QonversionRemoteConfigListCallback {
            override fun onSuccess(remoteConfigList: QRemoteConfigList) {
                resultListener.onSuccess(remoteConfigList.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        }

        Qonversion.shared.remoteConfigList(callback)
    }

    fun attachUserToExperiment(experimentId: String, groupId: String, resultListener: ResultListener) {
        Qonversion.shared.attachUserToExperiment(experimentId, groupId, object : QonversionExperimentAttachCallback {
            override fun onSuccess() {
                resultListener.onSuccess(emptyResult(success = true))
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun detachUserFromExperiment(experimentId: String, resultListener: ResultListener) {
        Qonversion.shared.detachUserFromExperiment(experimentId, object : QonversionExperimentAttachCallback {
            override fun onSuccess() {
                resultListener.onSuccess(emptyResult(success = true))
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun attachUserToRemoteConfiguration(remoteConfigurationId: String, resultListener: ResultListener) {
        Qonversion.shared.attachUserToRemoteConfiguration(remoteConfigurationId, object :
            QonversionRemoteConfigurationAttachCallback {
            override fun onSuccess() {
                resultListener.onSuccess(emptyResult(success = true))
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    fun detachUserFromRemoteConfiguration(remoteConfigurationId: String, resultListener: ResultListener) {
        Qonversion.shared.detachUserFromRemoteConfiguration(remoteConfigurationId, object :
            QonversionRemoteConfigurationAttachCallback {
            override fun onSuccess() {
                resultListener.onSuccess(emptyResult(success = true))
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        })
    }

    // region Other

    fun syncHistoricalData() {
        Qonversion.shared.syncHistoricalData()
    }

    fun isFallbackFileAccessible(resultListener: ResultListener) {
        val isAccessible = Qonversion.shared.isFallbackFileAccessible()

        resultListener.onSuccess(emptyResult(success = isAccessible))
    }

    // endregion

    // region Private

    private fun emptyResult(success: Boolean): BridgeData {
        return mapOf("success" to success)
    }

    private fun configurePurchaseOptions(
        offerId: String?,
        applyOffer: Boolean?,
        oldProduct: QProduct? = null,
        updatePolicyKey: String? = null,
        contextKeys: List<String>? = null,
    ): QPurchaseOptions {
        val builder = QPurchaseOptions.Builder()

        oldProduct?.let {
            builder.setOldProduct(it)
        }

        updatePolicyKey?.let {
            try {
                QPurchaseUpdatePolicy.valueOf(it)
            } catch (e: IllegalArgumentException) {
                null
            }
        }?.let {
            builder.setUpdatePolicy(it)
        }

        offerId?.let {
            builder.setOfferId(it)
        }

        if (applyOffer == false) {
            builder.removeOffer()
        }

        contextKeys?.let {
            builder.setContextKeys(it)
        }

        val purchaseOptions = builder.build()

        return purchaseOptions
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

    private fun getUserCallback(resultListener: ResultListener) =
        object : QonversionUserCallback {
            override fun onSuccess(user: QUser) {
                resultListener.onSuccess(user.toMap())
            }

            override fun onError(error: QonversionError) {
                resultListener.onError(error.toSandwichError())
            }
        }

    // endregion
}