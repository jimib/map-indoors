import UIKit
import Flutter
import GoogleMaps
import MapsIndoors

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GeneratedPluginRegistrant.register(with: self)

    GMSServices.provideAPIKey("GOOGLE_SERVICES_KEY")
    MapsIndoors.provideAPIKey("MAP_INDOORS_KEY",
      googleAPIKey:"GOOGLE_SERVICES_KEY"
    )

    weak var registrar = self.registrar(forPlugin: "plugin-name")

    let factory = FLNativeViewFactory(messenger: registrar!.messenger())
    self.registrar(forPlugin: "<plugin-name>")!.register(
        factory,
        withId: "<platform-view-type>")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
