package io.qonversion.sandwich

private const val QONVERSION_KEY_PREFIX = "com.qonversion.keys"
internal const val QONVERSION_KEY_SOURCE = "$QONVERSION_KEY_PREFIX.source"
internal const val QONVERSION_KEY_VERSION = "$QONVERSION_KEY_PREFIX.sourceVersion"

internal const val NO_CODES_PREFS_NAME = "io.qonversion.nocodes"
internal const val NO_CODES_KEY_SOURCE = "source"
internal const val NO_CODES_KEY_VERSION = "sourceVersion"

typealias BridgeData = Map<String, Any?>
