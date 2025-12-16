package io.qonversion.sandwich

interface NoCodesPurchaseDelegateBridge {
    fun purchase(product: BridgeData)
    fun restore()
}
