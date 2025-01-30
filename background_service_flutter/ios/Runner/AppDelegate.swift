import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register background tasks
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "task-identifier")
    
    // Register a periodic task (for iOS 13+)
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "be.tramckrijte.workmanagerExample.iOSBackgroundAppRefresh", frequency: NSNumber(value: 20 * 60))
    
    // Set minimum background fetch interval to 15 minutes (60 * 15 seconds)
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60 * 15))
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
