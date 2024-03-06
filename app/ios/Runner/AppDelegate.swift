import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }
        
        // Setup method channel
        methodChannel = FlutterMethodChannel(name: "receive_sharing_intent/messages", binaryMessenger: controller.binaryMessenger)
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
        let eventChannel = FlutterEventChannel(name: "receive_sharing_intent/events-media", binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Application called to open URL: \(url)")
        
        if url.pathExtension == "candle" {
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
        
        return super.application(app, open: url, options: options)
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
