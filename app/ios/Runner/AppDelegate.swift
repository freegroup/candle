import UIKit
import Flutter
import receive_sharing_intent

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("application inital.......")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("Application called to open URL: \(url)")
    
    // Ensure the URL is a file URL and that the file has the correct extension
    guard url.isFileURL && url.pathExtension == "candle" else {
      return false
    }

    // Start accessing a security-scoped resource.
    guard url.startAccessingSecurityScopedResource() else {
      // Handle the failure here if you can't access the resource.
      return false
    }

    // Your app should read the file and process the contents.
    do {
      let fileData = try Data(contentsOf: url)
      // Process the file data (e.g., pass to Flutter/Dart side for handling)
    } catch {
      print("Failed to read the file: \(error)")
      url.stopAccessingSecurityScopedResource()
      return false
    }

    // Stop accessing the security-scoped resource
    url.stopAccessingSecurityScopedResource()

    return true
  }

  // Add any additional methods needed to process the file data as appropriate for your app.
}
