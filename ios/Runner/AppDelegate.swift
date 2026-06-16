import Flutter
import CFNetwork
import UIKit
import StoreKit
import TDMobRisk

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let nativeBridgeChannelName = "funny_loan/native_bridge"
  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private var hasConfiguredTrustDecision = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let registrar = self.registrar(forPlugin: nativeBridgeChannelName) {
      let channel = FlutterMethodChannel(
        name: nativeBridgeChannelName,
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self else {
          result(
            FlutterError(
              code: "APP_DELEGATE_DEALLOCATED",
              message: "AppDelegate is unavailable",
              details: nil
            )
          )
          return
        }
        switch call.method {
        case "getSystemProxy":
          result(self.systemProxySettings())
        case "showTrustDecisionLiveness":
          self.showTrustDecisionLiveness(call.arguments, result: result)
        case "requestAppReview":
          self.requestAppReview(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    DispatchQueue.main.async { [weak self] in
        self?.configureTrustDecisionIfNeeded()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func systemProxySettings() -> [String: Any]? {
    guard
      let unmanaged = CFNetworkCopySystemProxySettings(),
      let settings = unmanaged.takeRetainedValue() as? [String: Any]
    else {
      return ["enabled": false, "host": "", "port": 0]
    }

    if let proxy = proxyValue(from: settings, scheme: "HTTP") {
      return proxy
    }
    if let proxy = proxyValue(from: settings, scheme: "HTTPS") {
      return proxy
    }
    return ["enabled": false, "host": "", "port": 0]
  }

  private func proxyValue(from settings: [String: Any], scheme: String) -> [String: Any]? {
    let enableKey = "\(scheme)Enable"
    let hostKey = "\(scheme)Proxy"
    let portKey = "\(scheme)Port"

    let enabled = (settings[enableKey] as? NSNumber)?.intValue == 1
    let host = settings[hostKey] as? String ?? ""
    let port =
      (settings[portKey] as? NSNumber)?.intValue ??
      (settings[portKey] as? Int ?? 0)

    guard enabled, !host.isEmpty, port > 0 else {
      return nil
    }

    return [
      "enabled": true,
      "host": host,
      "port": port
    ]
  }

  private func configureTrustDecisionIfNeeded() {
    var params: [String: Any] = [
      "partner": trustDecisionPartnerCode,
      "appKey": trustDecisionPartnerKey,
      "country": "sg",
      "language": "en",
    ]
#if DEBUG
    params["allowed"] = true
#endif
    trustDecisionManager?.pointee.initWithOptions(params)
  }

  private func showTrustDecisionLiveness(
    _ arguments: Any?,
    result: @escaping FlutterResult
  ) {
      let unwarned = arguments as? String
      guard let viewController = topViewController() else {
          result([
              "success": "find ViewController Error",
              "code": "0",
              "message": "find ViewController Error",
              "raw": ""])
          return
      }
      trustDecisionManager?.pointee.showLivenessWithShowStyle(
        viewController,
        unwarned,
        TDLivenessShowStylePresent,
        { successResult in
          result(self.wrapLivenessResult(success: true, payload: successResult))
        },
        { failResult in
          result(self.wrapLivenessResult(success: false, payload: failResult))
        }
      )
  }

  private func requestAppReview(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview()
      }
      result(true)
    }
  }

  private func wrapLivenessResult(success: Bool, payload: [AnyHashable: Any]?) -> [String: Any] {
    let raw = (payload as? [String: Any]) ?? [:]
    let code = (raw["code"] as? NSNumber)?.intValue ?? (success ? 0 : -1)
    let message = raw["message"] as? String ?? ""
    let image = raw["image"] as? String ?? ""
    let sequenceId = raw["sequence_id"] as? String ?? ""
    let livenessId = raw["liveness_id"] as? String ?? ""
    return [
      "success": success,
      "code": code,
      "message": message,
      "image": image,
      "sequence_id": sequenceId,
      "liveness_id": livenessId,
      "raw": raw
    ]
  }

  private func topViewController(
    from viewController: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }
    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }
    return viewController
  }
}
