import Flutter
import UIKit
import UserMessagingPlatform

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let umpChannel = FlutterMethodChannel(name: "consent.ump",
                                          binaryMessenger: controller.binaryMessenger)
    umpChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "requestConsent" {
        print("requestConsent method called from Flutter")
        self.requestConsent(result: result)
      } else {
        result(FlutterMethodNotImplemented)
        return
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestConsent(result: @escaping FlutterResult) {
    print("Requesting consent")
    let parameters = UMPRequestParameters()
    parameters.tagForUnderAgeOfConsent = false

    UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
      if let error = error {
        print("Failed to update consent info: \(error.localizedDescription)")
        result(FlutterError(code: "UMPError", message: error.localizedDescription, details: nil))
        return
      }

      print("Consent info updated")
      if UMPConsentInformation.sharedInstance.consentStatus == .required {
        print("Consent required")
        UMPConsentForm.load { form, loadError in
          if let loadError = loadError {
            print("Failed to load consent form: \(loadError.localizedDescription)")
            result(FlutterError(code: "UMPError", message: loadError.localizedDescription, details: nil))
            return
          }

          print("Consent form loaded successfully")
          form?.present(from: self.window?.rootViewController) { dismissError in
            if let dismissError = dismissError {
              print("Failed to present consent form: \(dismissError.localizedDescription)")
              result(FlutterError(code: "UMPError", message: dismissError.localizedDescription, details: nil))
              return
            }

            print("Consent obtained successfully")
            result("Consent obtained")
          }
        }
      } else {
        print("Consent not required")
        result("Consent not required")
      }
    }
  }
}
