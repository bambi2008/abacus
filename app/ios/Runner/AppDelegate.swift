import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let ocrRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "ReceiptOcrPlugin"
    ) else {
      assertionFailure("Unable to create the ReceiptOcrPlugin registrar")
      return
    }
    ReceiptOcrPlugin.register(with: ocrRegistrar)
  }
}
