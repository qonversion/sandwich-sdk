package io.qonversion.sandwich

interface AsyncEventsListener {

    fun onPermissionsUpdateAfterAsyncPurchase(permissions: BridgeData)
}