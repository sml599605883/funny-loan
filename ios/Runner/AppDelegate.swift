import Flutter
import CFNetwork
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let proxyChannelName = "funny_loan/network_proxy"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let registrar = self.registrar(forPlugin: proxyChannelName) {
      let channel = FlutterMethodChannel(
        name: proxyChannelName,
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard call.method == "getSystemProxy" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(self?.systemProxySettings())
      }
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
}
