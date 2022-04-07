package io.qonversion.sandwich

interface ResultListener {

    fun onSuccess(data: Map<String, Any?>)

    fun onError(error: Map<String, Any?>)
}