package de.freegroup.candle

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AttestationChannel(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
        AccessibilityChannel(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
