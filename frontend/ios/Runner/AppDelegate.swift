import UIKit
import Flutter
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase with more defensive error handling
    configureFirebaseSafely()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func configureFirebaseSafely() {
    // Try to configure Firebase in both debug and release modes, but handle errors gracefully
    guard FirebaseApp.app() == nil else {
      print("Firebase already configured")
      return
    }
    
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          FileManager.default.fileExists(atPath: path) else {
      print("GoogleService-Info.plist not found, skipping Firebase configuration")
      return
    }
    
    do {
      print("Attempting Firebase configuration...")
      FirebaseApp.configure()
      print("Firebase configured successfully")
    } catch {
      print("Firebase configuration failed with error: \(error)")
      print("Continuing without Firebase...")
    }
  }
}
