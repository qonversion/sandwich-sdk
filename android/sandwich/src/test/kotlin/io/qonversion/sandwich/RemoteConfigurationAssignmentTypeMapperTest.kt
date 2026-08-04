package io.qonversion.sandwich

import org.junit.Assert.assertEquals
import org.junit.Test

class RemoteConfigurationAssignmentTypeMapperTest {
    @Test
    fun `bridge preserves frozen and fails safe for future values`() {
        assertEquals("auto", remoteConfigurationAssignmentTypeNameToFormattedString("Auto"))
        assertEquals("manual", remoteConfigurationAssignmentTypeNameToFormattedString("Manual"))
        assertEquals("frozen", remoteConfigurationAssignmentTypeNameToFormattedString("Frozen"))
        assertEquals("unknown", remoteConfigurationAssignmentTypeNameToFormattedString("Future"))
    }
}
