package io.qonversion.sandwich

interface QonversionEventsListener {

    fun onEntitlementsUpdated(entitlements: BridgeData)

    fun onDeferredPurchaseCompleted(transaction: BridgeData)
}
