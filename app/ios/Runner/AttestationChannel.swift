import CryptoKit
import DeviceCheck
import Flutter

/// App Attest for the Candle server (channel "candle/attestation", see
/// lib/data/services/attestation/attestation_service.dart and server/README.md).
///
/// The device proves itself for SHA-256(challenge) of a server challenge.
class AttestationChannel: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "candle/attestation", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(AttestationChannel(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let service = DCAppAttestService.shared
        // false on the simulator
        guard service.isSupported else {
            return result(FlutterError(code: "unsupported", message: "App Attest is not available", details: nil))
        }
        let arguments = call.arguments as? [String: Any]
        guard let challenge = arguments?["challenge"] as? String else {
            return result(FlutterError(code: "bad_arguments", message: "challenge is missing", details: nil))
        }
        let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))

        // App Attest calls back on a background queue, Flutter wants the main thread.
        let reply: (Any?) -> Void = { value in DispatchQueue.main.async { result(value) } }

        switch call.method {
        case "attestKey":
            service.generateKey { keyId, error in
                guard let keyId else { return reply(Self.flutterError(error)) }
                service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
                    guard let attestation else { return reply(Self.flutterError(error)) }
                    reply(["keyId": keyId, "attestation": attestation.base64EncodedString()])
                }
            }
        case "generateAssertion":
            guard let keyId = arguments?["keyId"] as? String else {
                return result(FlutterError(code: "bad_arguments", message: "keyId is missing", details: nil))
            }
            service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
                guard let assertion else { return reply(Self.flutterError(error)) }
                reply(["assertion": assertion.base64EncodedString()])
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func flutterError(_ error: Error?) -> FlutterError {
        // The key is gone (e.g. app restored on another phone): the app registers again.
        if let error = error as? DCError, error.code == .invalidKey {
            return FlutterError(code: "invalid_key", message: error.localizedDescription, details: nil)
        }
        return FlutterError(code: "attestation_failed", message: error?.localizedDescription, details: nil)
    }
}
