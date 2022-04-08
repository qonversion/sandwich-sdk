package io.qonversion.sandwich

interface QonversionEventsListener {

    fun onPermissionsUpdateAfterAsyncPurchase(permissions: BridgeData)
}