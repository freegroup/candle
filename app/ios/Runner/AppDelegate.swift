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
    
    let sharingIntent = SwiftReceiveSharingIntentPlugin.instance
    if url.pathExtension == "candle" {
       print("matching URL schema")
       return sharingIntent.application(app, open: url, options: options)
    }
      
    // For example load MSALPublicClientApplication
    // return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[.sourceApplication] as? String)

    // Cancel url handling
    // return false

    // Proceed url handling for other Flutter libraries like uni_links
    return super.application(app, open: url, options:options)
  }

  // Add any additional methods needed to process the file data as appropriate for your app.
}
