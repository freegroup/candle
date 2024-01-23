package de.freegroup.candle

import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "de.freegroup/native"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSha1Key") {
                try {
                    val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                    for (signature in info.signatures) {
                        val md = MessageDigest.getInstance("SHA-1")
                        md.update(signature.toByteArray())
                        val sha1Bytes = md.digest()
                        val sha1Hex = sha1Bytes.joinToString(":") { String.format("%02X", it) }
                        result.success(sha1Hex)
                    }
                } catch (e: PackageManager.NameNotFoundException) {
                    Log.e("SHA1", "NameNotFoundException", e)
                    result.error("NameNotFoundException", e.message, null)
                } catch (e: NoSuchAlgorithmException) {
                    Log.e("SHA1", "NoSuchAlgorithmException", e)
                    result.error("NoSuchAlgorithmException", e.message, null)
                }
            }
        }
    }
}
