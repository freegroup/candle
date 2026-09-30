package de.freegroup.candle

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityToken
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Play Integrity (standard requests) for the Candle server, channel "candle/attestation",
 * see lib/data/services/attestation/attestation_service.dart and server/README.md.
 *
 * The token is bound to requestHash = hex(SHA-256(challenge)) of a server challenge.
 */
class AttestationChannel(context: Context) : MethodChannel.MethodCallHandler {
    private val manager = IntegrityManagerFactory.createStandard(context)

    // Preparing is slow (seconds); Google recommends reusing the provider.
    private var provider: StandardIntegrityTokenProvider? = null
    private var providerProject = 0L

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "candle/attestation").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "integrityToken") return result.notImplemented()

        val challenge = call.argument<String>("challenge")
        val project = call.argument<Number>("cloudProjectNumber")?.toLong() ?: 0L
        if (challenge == null || project == 0L) {
            return result.error("bad_arguments", "challenge and cloudProjectNumber are required", null)
        }
        val requestHash = MessageDigest.getInstance("SHA-256")
            .digest(challenge.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }

        withProvider(project, result) { provider ->
            provider.request(StandardIntegrityTokenRequest.builder().setRequestHash(requestHash).build())
                .addOnSuccessListener { token: StandardIntegrityToken ->
                    result.success(mapOf("integrityToken" to token.token()))
                }
                .addOnFailureListener { error ->
                    // e.g. the provider expired: prepare a new one next time
                    this.provider = null
                    result.error("attestation_failed", error.message, null)
                }
        }
    }

    private fun withProvider(
        project: Long,
        result: MethodChannel.Result,
        use: (StandardIntegrityTokenProvider) -> Unit,
    ) {
        provider?.takeIf { providerProject == project }?.let { return use(it) }

        manager.prepareIntegrityToken(PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(project).build())
            .addOnSuccessListener { prepared ->
                provider = prepared
                providerProject = project
                use(prepared)
            }
            .addOnFailureListener { error -> result.error("attestation_failed", error.message, null) }
    }
}
