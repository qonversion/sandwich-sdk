package io.qonversion.sandwich

import com.android.billingclient.api.SkuDetails
import com.qonversion.android.sdk.dto.QonversionError
import com.qonversion.android.sdk.automations.dto.AutomationsEvent
import com.qonversion.android.sdk.automations.dto.QActionResult
import com.qonversion.android.sdk.automations.dto.QScreenPresentationConfig
import com.qonversion.android.sdk.automations.dto.QScreenPresentationStyle
import com.qonversion.android.sdk.dto.QEntitlement
import com.qonversion.android.sdk.dto.QUser
import com.qonversion.android.sdk.dto.eligibility.QEligibility
import com.qonversion.android.sdk.dto.experiments.QExperimentInfo
import com.qonversion.android.sdk.dto.offerings.QOffering
import com.qonversion.android.sdk.dto.offerings.QOfferings
import com.qonversion.android.sdk.dto.products.QProduct

fun QonversionError.toSandwichError(): SandwichError {
    return SandwichError(this)
}

fun QonversionError.toMap(): BridgeData {
    return mapOf(
        "code" to code.toString(),
        "description" to description,
        "additionalMessage" to additionalMessage
    )
}

fun SkuDetails.toMap(): BridgeData {
    return mapOf(
        "description" to description,
        "freeTrialPeriod" to freeTrialPeriod,
        "iconUrl" to iconUrl,
        "introductoryPrice" to introductoryPrice,
        "introductoryPriceAmountMicros" to introductoryPriceAmountMicros,
        "introductoryPriceCycles" to introductoryPriceCycles,
        "introductoryPricePeriod" to introductoryPricePeriod,
        "originalJson" to originalJson,
        "originalPrice" to originalPrice,
        "originalPriceAmountMicros" to originalPriceAmountMicros,
        "price" to price,
        "priceAmountMicros" to priceAmountMicros,
        "priceCurrencyCode" to priceCurrencyCode,
        "sku" to sku,
        "subscriptionPeriod" to subscriptionPeriod,
        "title" to title,
        "type" to type,
        "hashCode" to hashCode(),
        "toString" to toString()
    )
}

fun QProduct.toMap(): BridgeData {
    return mapOf(
        "id" to qonversionID,
        "storeId" to storeID,
        "type" to type.type,
        "duration" to duration?.type,
        "skuDetails" to skuDetail?.toMap(),
        "prettyPrice" to prettyPrice,
        "trialDuration" to trialDuration.type,
        "offeringId" to offeringID
    )
}

fun Map<String, QProduct>.toProductsMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QEntitlement.toMap(): BridgeData {
    return mapOf(
        "id" to id,
        "startedTimestamp" to startedDate.time.toDouble(),
        "expirationTimestamp" to expirationDate?.time?.toDouble(),
        "active" to isActive,
        "source" to source.name,
        "productId" to productId,
        "renewState" to renewState.type
    )
}

fun Map<String, QEntitlement>.toEntitlementsMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QOffering.toMap(): BridgeData {
    return mapOf(
        "id" to offeringID,
        "tag" to tag.tag,
        "products" to products.map { it.toMap() }
    )
}

fun QOfferings.toMap(): BridgeData {
    return mapOf(
        "main" to main?.toMap(),
        "availableOfferings" to availableOfferings.map { it.toMap() }
    )
}

fun QEligibility.toMap(): BridgeData {
    return mapOf("status" to status.type)
}

fun QUser.toMap(): BridgeData {
    return mapOf(
        "qonversionId" to qonversionId,
        "identityId" to identityId
    )
}

fun Map<String, QEligibility>.toEligibilityMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QExperimentInfo.toMap(): BridgeData {
    return mapOf(
        "id" to experimentID,
        "group" to mapOf("type" to 0)
    )
}

fun Map<String, QExperimentInfo>.toExperimentsMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QActionResult.toMap(): BridgeData {
    return mapOf(
        "type" to type.type,
        "value" to value,
        "error" to error?.toMap()
    )
}

fun AutomationsEvent.toMap(): BridgeData {
    return mapOf(
        "type" to type.type,
        "timestamp" to date.time.toDouble()
    )
}

fun Map<String, Any?>.toStringMap(): Map<String, String> {
    return filterValues { it != null }
        .mapValues { it.value.toString() }
}

fun Map<String, Any?>.toScreenPresentationConfig(): QScreenPresentationConfig {
    val presentationStyle = try {
        get("presentationStyle")?.takeIf { it is String }?.let {
            QScreenPresentationStyle.valueOf(it as String)
        }
    } catch (e: IllegalArgumentException) {
        null
    }

    return presentationStyle?.let { QScreenPresentationConfig(it) } ?: QScreenPresentationConfig()
}
