package de.freegroup.candle

import android.content.Context
import android.view.accessibility.AccessibilityManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Screen reader controls Flutter does not offer, channel "candle/accessibility",
 * see lib/data/services/accessibility/accessibility_service.dart.
 */
class AccessibilityChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "candle/accessibility").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "interrupt") return result.notImplemented()

        val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        // interrupt() throws while no accessibility service runs
        if (manager.isEnabled) manager.interrupt()
        result.success(null)
    }
}
