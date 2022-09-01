package io.qonversion.sandwich

import com.android.billingclient.api.SkuDetails
import com.qonversion.android.sdk.QonversionError
import com.qonversion.android.sdk.automations.AutomationsEvent
import com.qonversion.android.sdk.automations.QActionResult
import com.qonversion.android.sdk.dto.QLaunchResult
import com.qonversion.android.sdk.dto.QPermission
import com.qonversion.android.sdk.dto.QPermissionsCacheLifetime
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
        "trialDuration" to trialDuration?.type,
        "offeringId" to offeringID
    )
}

fun Map<String, QProduct>.toProductsMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QPermission.toMap(): BridgeData {
    return mapOf(
        "id" to permissionID,
        "associatedProduct" to productID,
        "renewState" to renewState.type,
        "startedTimestamp" to startedDate.time.toDouble(),
        "expirationTimestamp" to expirationDate?.time?.toDouble(),
        "active" to isActive()
    )
}

fun Map<String, QPermission>.toPermissionsMap(): BridgeData {
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

fun Map<String, QEligibility>.toEligibilityMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QLaunchResult.toMap(): BridgeData {
    return mapOf(
        "uid" to uid,
        "timestamp" to date.time.toDouble(),
        "products" to products.toProductsMap(),
        "permissions" to permissions.toPermissionsMap(),
        "userProducts" to userProducts.toProductsMap()
    )
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

fun String.toPermissionsCacheLifetime(): QPermissionsCacheLifetime {
    val convertedKeys = mapOf(
        "Week" to "WEEK",
        "TwoWeeks" to "TWO_WEEKS",
        "Month" to "MONTH",
        "TwoMonths" to "TWO_MONTHS",
        "ThreeMonths" to "THREE_MONTHS",
        "SixMonths" to "SIX_MONTHS",
        "Year" to "YEAR",
        "Unlimited" to "UNLIMITED"
    )

    val convertedKey = convertedKeys[this]
        ?: throw IllegalArgumentException("Unsupported lifetime key - $this")

    return QPermissionsCacheLifetime.valueOf(convertedKey)
}
