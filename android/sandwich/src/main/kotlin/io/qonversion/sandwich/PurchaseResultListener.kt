package io.qonversion.sandwich

interface PurchaseResultListener {

    fun onSuccess(data: Map<String, Any?>)

    fun onError(error: SandwichError, isCancelled: Boolean)
}