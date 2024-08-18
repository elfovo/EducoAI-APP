import UIKit
import Flutter
import Firebase
import GoogleSignIn
import UserMessagingPlatform

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("didFinishLaunchingWithOptions called")

        FirebaseApp.configure()
        print("FirebaseApp configured")

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Firebase client ID not found")
            return true
        }

        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        print("GIDConfiguration clientID set to \(clientID)")

        GeneratedPluginRegistrant.register(with: self)

        // Configure the FlutterMethodChannel for consent
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let umpChannel = FlutterMethodChannel(name: "consent.ump",
                                              binaryMessenger: controller.binaryMessenger)
        umpChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "requestConsent" {
                print("requestConsent method called from Flutter")
                self.requestConsent(result: result)
            } else if call.method == "resetConsent" {
                print("resetConsent method called from Flutter")
                self.resetConsent(result: result)
            } else {
                result(FlutterMethodNotImplemented)
                return
            }
        })

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func requestConsent(result: @escaping FlutterResult) {
        let userDefaults = UserDefaults.standard
        let consentShownKey = "consentShown"

        if userDefaults.bool(forKey: consentShownKey) {
            print("Consent already shown, not displaying again.")
            result("Consent already shown")
            return
        }

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
                    if let rootViewController = self.window?.rootViewController {
                        form?.present(from: rootViewController) { dismissError in
                            if let dismissError = dismissError {
                                print("Failed to present consent form: \(dismissError.localizedDescription)")
                                result(FlutterError(code: "UMPError", message: dismissError.localizedDescription, details: nil))
                                return
                            }

                            print("Consent obtained successfully")
                            userDefaults.set(true, forKey: consentShownKey)
                            result("Consent obtained")
                        }
                    } else {
                        print("Root view controller is nil")
                        result(FlutterError(code: "UMPError", message: "Root view controller is nil", details: nil))
                    }
                }
            } else {
                print("Consent not required")
                userDefaults.set(true, forKey: consentShownKey)
                result("Consent not required")
            }
        }
    }

    private func resetConsent(result: @escaping FlutterResult) {
        let userDefaults = UserDefaults.standard
        let consentShownKey = "consentShown"
        userDefaults.removeObject(forKey: consentShownKey)
        UMPConsentInformation.sharedInstance.reset()
        print("Consent reset")
        result("Consent reset")
    }
}
