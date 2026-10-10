import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?

    // UIScene lifecycle (required by iOS 27): the engine only exists once the scene is
    // connected, so plugins and channels are set up here, not in didFinishLaunching.
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        // Before the plugins, so a .candle file is handled here and not offered to them.
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CandleFileOpen") {
            registrar.addSceneDelegate(self)
        }
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AttestationChannel") {
            AttestationChannel.register(with: registrar)
        }

        let messenger = engineBridge.applicationRegistrar.messenger()

        // Setup method channel
        methodChannel = FlutterMethodChannel(name: "receive_sharing_intent/messages", binaryMessenger: messenger)
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            // Handle method calls here
            if call.method == "getInitialMedia" {
                // Respond with initial media if any, e.g., from launchOptions or saved state
                // For simplicity, responding with nil or an empty list
                result(nil)
            } else if call.method == "reset" {
                 // Implement logic to handle the reset call from Flutter
                 // This could involve clearing any stored references to initial media data
                 result(nil) // Respond to indicate successful handling
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        // Setup event channel
        let eventChannel = FlutterEventChannel(name: "receive_sharing_intent/events-media", binaryMessenger: messenger)
        eventChannel.setStreamHandler(self)
    }

}

extension AppDelegate: FlutterSceneLifeCycleDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard let url = URLContexts.first?.url, url.pathExtension == "candle" else {
            return false
        }
        print("Application called to open URL: \(url)")

        // Handle the .candle file
        // Prepare the data to be sent to Flutter
        let fileInfo = [["path": url.path, "type": "file"]]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: fileInfo, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            // Make sure to send the jsonString to the event channel
            self.eventSink?(jsonString)
        } catch {
            print("Error preparing shared file info: \(error)")
        }

        return true
    }
}

extension AppDelegate: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // Optionally, send any initial event if necessary
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
