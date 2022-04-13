package io.qonversion.sandwich

import com.qonversion.android.sdk.QonversionError

class SandwichError(
    val code: String,
    val description: String,
    val additionalMessage: String
) {
    constructor(error: QonversionError) : this(
        error.code.toString(),
        error.description,
        error.additionalMessage
    )
}