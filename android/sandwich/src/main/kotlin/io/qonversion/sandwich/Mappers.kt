package io.qonversion.sandwich

import com.android.billingclient.api.*
import com.qonversion.android.sdk.dto.QonversionError
import com.qonversion.android.sdk.automations.dto.QActionResult
import com.qonversion.android.sdk.automations.dto.QScreenPresentationConfig
import com.qonversion.android.sdk.automations.dto.QScreenPresentationStyle
import com.qonversion.android.sdk.dto.QRemoteConfig
import com.qonversion.android.sdk.dto.QRemoteConfigurationAssignmentType
import com.qonversion.android.sdk.dto.QRemoteConfigurationSource
import com.qonversion.android.sdk.dto.QRemoteConfigurationSourceType
import com.qonversion.android.sdk.dto.QUser
import com.qonversion.android.sdk.dto.eligibility.QEligibility
import com.qonversion.android.sdk.dto.entitlements.QEntitlement
import com.qonversion.android.sdk.dto.entitlements.QTransaction
import com.qonversion.android.sdk.dto.experiments.QExperiment
import com.qonversion.android.sdk.dto.experiments.QExperimentGroup
import com.qonversion.android.sdk.dto.experiments.QExperimentGroupType
import com.qonversion.android.sdk.dto.offerings.QOffering
import com.qonversion.android.sdk.dto.offerings.QOfferings
import com.qonversion.android.sdk.dto.products.QProduct
import com.qonversion.android.sdk.dto.products.QProductInAppDetails
import com.qonversion.android.sdk.dto.products.QProductOfferDetails
import com.qonversion.android.sdk.dto.products.QSubscriptionPeriod
import com.qonversion.android.sdk.dto.products.QProductPrice
import com.qonversion.android.sdk.dto.products.QProductPricingPhase
import com.qonversion.android.sdk.dto.products.QProductStoreDetails
import com.qonversion.android.sdk.dto.properties.QUserProperties
import com.qonversion.android.sdk.dto.properties.QUserProperty

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

@Suppress("DEPRECATION")
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

@Suppress("DEPRECATION")
fun QProduct.toMap(): BridgeData {
    return mapOf(
        "id" to qonversionID,
        "storeId" to storeID,
        "basePlanId" to basePlanID,
        "type" to type.name,
        "subscriptionPeriod" to subscriptionPeriod?.toMap(),
        "trialPeriod" to trialPeriod?.toMap(),
        "skuDetails" to skuDetail?.toMap(),
        "storeDetails" to storeDetails?.toMap(),
        "prettyPrice" to prettyPrice,
        "offeringId" to offeringID
    )
}

fun QSubscriptionPeriod.toMap(): BridgeData {
    return mapOf(
        "unitCount" to unitCount,
        "unit" to unit.name,
        "iso" to iso
    )
}

fun QProductPricingPhase.toMap(): BridgeData {
    return mapOf(
        "price" to price.toMap(),
        "billingPeriod" to billingPeriod.toMap(),
        "billingCycleCount" to billingCycleCount,
        "recurrenceMode" to recurrenceMode.name,
        "type" to type.name,
        "isTrial" to isTrial,
        "isIntro" to isIntro,
        "isBasePlan" to isBasePlan
    )
}
fun QProductOfferDetails.toMap(): BridgeData {
    return mapOf(
        "basePlanId" to basePlanId,
        "offerId" to offerId,
        "offerToken" to offerToken,
        "tags" to tags,
        "pricingPhases" to pricingPhases.map { it.toMap() },
        "basePlan" to basePlan?.toMap(),
        "trialPhase" to trialPhase?.toMap(),
        "introPhase" to introPhase?.toMap(),
        "hasTrial" to hasTrial,
        "hasIntro" to hasIntro,
        "hasTrialOrIntro" to hasTrialOrIntro
    )
}

fun QProductPrice.toMap(): BridgeData {
    return mapOf(
        "priceAmountMicros" to priceAmountMicros,
        "priceCurrencyCode" to priceCurrencyCode,
        "formattedPrice" to formattedPrice,
        "isFree" to isFree,
        "currencySymbol" to currencySymbol
    )
}

fun QProductInAppDetails.toMap(): BridgeData {
    return mapOf(
        "price" to price.toMap()
    )
}

fun QProductStoreDetails.toMap(): BridgeData {
    return mapOf(
        "basePlanId" to basePlanId,
        "productId" to productId,
        "name" to name,
        "title" to title,
        "description" to description,
        "subscriptionOfferDetails" to subscriptionOfferDetails?.map { it.toMap() },
        "defaultSubscriptionOfferDetails" to defaultSubscriptionOfferDetails?.toMap(),
        "basePlanSubscriptionOfferDetails" to basePlanSubscriptionOfferDetails?.toMap(),
        "inAppOfferDetails" to inAppOfferDetails?.toMap(),
        "hasTrialOffer" to hasTrialOffer,
        "hasIntroOffer" to hasIntroOffer,
        "hasTrialOrIntroOffer" to hasTrialOrIntroOffer,
        "productType" to productType.name,
        "isInApp" to isInApp,
        "isSubscription" to isSubscription,
        "isPrepaid" to isPrepaid,
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
        "renewState" to renewState.type,
        "renewsCount" to renewsCount,
        "trialStartTimestamp" to trialStartDate?.time?.toDouble(),
        "firstPurchaseTimestamp" to firstPurchaseDate?.time?.toDouble(),
        "lastPurchaseTimestamp" to lastPurchaseDate?.time?.toDouble(),
        "lastActivatedOfferCode" to lastActivatedOfferCode,
        "autoRenewDisableTimestamp" to autoRenewDisableDate?.time?.toDouble(),
        "grantType" to grantType.name,
        "transactions" to transactions.map { it.toMap() }
    )
}

fun QTransaction.toMap(): BridgeData {
    return mapOf(
        "originalTransactionId" to originalTransactionId,
        "transactionId" to transactionId,
        "offerCode" to offerCode,
        "transactionTimestamp" to transactionDate.time.toDouble(),
        "expirationTimestamp" to expirationDate?.time?.toDouble(),
        "transactionRevocationTimestamp" to transactionRevocationDate?.time?.toDouble(),
        "ownershipType" to ownershipType.name,
        "type" to type.name,
        "environment" to environment.name
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

fun QUserProperty.toMap(): BridgeData {
    return mapOf(
        "key" to key,
        "value" to value,
    )
}

fun QUserProperties.toMap(): BridgeData {
    val propertiesData = properties.map { it.toMap() }
    return mapOf("properties" to propertiesData)
}

fun Map<String, QEligibility>.toEligibilityMap(): BridgeData {
    return mapValues { it.value.toMap() }
}

fun QRemoteConfig.toMap(): BridgeData {
    return mapOf(
        "payload" to payload,
        "experiment" to experiment?.toMap(),
        "source" to source.toMap()
    )
}

fun QExperiment.toMap(): BridgeData {
    return mapOf(
        "id" to id,
        "name" to name,
        "group" to group.toMap()
    )
}

fun QExperimentGroup.toMap(): BridgeData {
    return mapOf(
        "id" to id,
        "name" to name,
        "type" to type.toFormattedString()
    )
}

fun QExperimentGroupType.toFormattedString(): String {
    return when (this) {
        QExperimentGroupType.Treatment -> "treatment"
        QExperimentGroupType.Control -> "control"
        else -> "unknown"
    }
}

fun QRemoteConfigurationSource.toMap(): BridgeData {
    return mapOf(
        "id" to id,
        "name" to name,
        "type" to type.toFormattedString(),
        "assignmentType" to assignmentType.toFormattedString(),
        "contextKey" to contextKey
    )
}

fun QRemoteConfigurationSourceType.toFormattedString(): String {
    return when (this) {
        QRemoteConfigurationSourceType.RemoteConfiguration -> "remote_configuration"
        QRemoteConfigurationSourceType.ExperimentTreatmentGroup -> "experiment_treatment_group"
        QRemoteConfigurationSourceType.ExperimentControlGroup -> "experiment_control_group"
        else -> "unknown"
    }
}

fun QRemoteConfigurationAssignmentType.toFormattedString(): String {
    return when (this) {
        QRemoteConfigurationAssignmentType.Auto -> "auto"
        QRemoteConfigurationAssignmentType.Manual -> "manual"
        else -> "unknown"
    }
}

fun QActionResult.toMap(): BridgeData {
    return mapOf(
        "type" to type.type,
        "value" to value,
        "error" to error?.toMap()
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
