import Flutter
import AdSupport
import AppTrackingTransparency
import CFNetwork
import CoreLocation
import CoreTelephony
import Darwin
import MachO
import NetworkExtension
import Security
import UIKit
import StoreKit
import SystemConfiguration.CaptiveNetwork
import TDMobRisk
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private let nativeBridgeChannelName = "funny_loan/native_bridge"
  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private var hasConfiguredTrustDecision = false
  private var flutterChannel: FlutterMethodChannel?
  private var locationManager: CLLocationManager?
  private var locationResults: [FlutterResult] = []
  private var requestingLocation = false
  private let geocoder = CLGeocoder()
  private var pushTokenResult: FlutterResult?
  private let pushTokenKey = "apns_token"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let registrar = self.registrar(forPlugin: nativeBridgeChannelName) {
      let channel = FlutterMethodChannel(
        name: nativeBridgeChannelName,
        binaryMessenger: registrar.messenger()
      )
      flutterChannel = channel
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
        case "getProxyEnabled":
          result(self.proxyEnabled())
        case "getVpnEnabled":
          result(self.vpnEnabled())
        case "getRooted":
          result(self.isJailbroken() ? 1 : 0)
        case "getIsEmulator":
#if targetEnvironment(simulator)
          result(1)
#else
          result(0)
#endif
        case "getDeviceLanguage":
          result(Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "")
        case "getCarrierName":
          result(self.carrierName())
        case "getNetworkType":
          result(self.currentNetworkType())
        case "getTimeZoneId":
          result(TimeZone.current.identifier)
        case "getCpuCores":
          result(ProcessInfo.processInfo.processorCount)
        case "getDeviceName":
          result(UIDevice.current.name)
        case "getScreenInches":
          result(self.currentScreenInches())
        case "getWifiInfo":
          self.wifiInfo(result: result)
        case "getDeviceStorageInfo":
          result(self.storageInfo())
        case "getIosIdentifiers":
          result([
            "idfv": FunnyLoanDeviceTools.shared.getIdfv(),
            "idfa": FunnyLoanDeviceTools.shared.getIdfa(),
          ])
        case "requestTrackingPermission":
          FunnyLoanDeviceTools.shared.requestIdfa { idfa, status in
            self.flutterChannel?.invokeMethod(
              "onTrackingAuthorizationChanged",
              arguments: ["status": status]
            )
            result(idfa)
          }
        case "getTrackingAuthorizationStatus":
          result(FunnyLoanDeviceTools.shared.currentTrackingStatusString())
        case "isLocationPermissionNotDetermined":
          result(self.locationStatusString() == "notDetermined")
        case "getPushToken":
          if let token = self.getStoredPushToken(), !token.isEmpty {
            result(token)
          } else {
            self.pushTokenResult = result
            self.requestPushTokenRegistration()
          }
        case "getCurrentLocation":
          self.currentLocation(result: result)
        case "getBatteryInfo":
          result(self.batteryInfo())
        case "getDeviceUptime":
          result(Int64(ProcessInfo.processInfo.systemUptime * 1000))
        case "getDeviceElapsedRealtime":
          result(Int64(Date().timeIntervalSince1970 * 1000))
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

  private func currentLocation(result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled(),
          locationStatusString() == "granted"
    else {
      result(nil)
      return
    }
    locationResults.append(result)
    if locationManager == nil {
      let manager = CLLocationManager()
      manager.delegate = self
      manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      locationManager = manager
    }
    if requestingLocation {
      return
    }
    requestingLocation = true
    locationManager?.requestLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      completeLocationResults(nil)
      return
    }
    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
      guard let self else { return }
      if error != nil {
        self.completeLocationResults([
          "latitude": "\(location.coordinate.latitude)",
          "longitude": "\(location.coordinate.longitude)",
        ])
        return
      }
      let place = placemarks?.first
      let payload: [String: Any] = [
        "adminArea": place?.administrativeArea ?? "",
        "countryCode": place?.isoCountryCode ?? "",
        "countryName": place?.country ?? "",
        "featureName": place?.name ?? "",
        "latitude": "\(location.coordinate.latitude)",
        "longitude": "\(location.coordinate.longitude)",
        "locality": place?.locality ?? "",
        "juxtaposition": place?.subLocality ?? "",
        "extemporaneous": place?.subAdministrativeArea ?? "",
      ]
      self.completeLocationResults(payload)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    completeLocationResults(nil)
  }

  private func completeLocationResults(_ payload: Any?) {
    requestingLocation = false
    let pending = locationResults
    locationResults.removeAll()
    for callback in pending {
      callback(payload)
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set(token, forKey: pushTokenKey)
    pushTokenResult?(token)
    pushTokenResult = nil
    flutterChannel?.invokeMethod("onPushTokenChanged", arguments: ["token": token])
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pushTokenResult?("")
    pushTokenResult = nil
  }

  private func getStoredPushToken() -> String? {
    UserDefaults.standard.string(forKey: pushTokenKey)
  }

  private func requestPushTokenRegistration() {
    UNUserNotificationCenter.current().delegate = self
    DispatchQueue.main.async {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }

  private func batteryInfo() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    let percent = level < 0 ? 0 : Int(level * 100)
    let state = UIDevice.current.batteryState
    let charging = (state == .charging || state == .full) ? 1 : 0
    return [
      "scow": percent,
      "structuration": charging,
    ]
  }

  private func proxyEnabled() -> Int {
    guard let proxySettingsUnmanaged = CFNetworkCopySystemProxySettings(),
          let url = URL(string: "http://www.google.com")
    else {
      return 0
    }
    let proxySettings = proxySettingsUnmanaged.takeRetainedValue()
    let proxiesUnmanaged = CFNetworkCopyProxiesForURL(url as CFURL, proxySettings)
    guard
      let proxies = proxiesUnmanaged.takeRetainedValue() as? [Any],
      let settings = proxies.first as? [String: Any],
      let proxyType = settings[kCFProxyTypeKey as String] as? String
    else {
      return 0
    }
    return proxyType == (kCFProxyTypeNone as String) ? 0 : 1
  }

  private func vpnEnabled() -> Int {
    guard let proxySettingsUnmanaged = CFNetworkCopySystemProxySettings() else {
      return 0
    }
    let proxySettings = proxySettingsUnmanaged.takeRetainedValue() as NSDictionary
    guard
      let dict = proxySettings["__SCOPED__"] as? NSDictionary,
      let keys = dict.allKeys as? [String]
    else {
      return 0
    }
    for key in keys {
      if ["tap", "tun", "ipsec", "ppp"].contains(where: { key.contains($0) }) {
        return 1
      }
    }
    return 0
  }

  private func isJailbroken() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    let jailbreakPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
    ]
    for path in jailbreakPaths {
      if FileManager.default.fileExists(atPath: path) {
        return true
      }
    }
    if let url = URL(string: "cydia://package/com.example.package"),
       UIApplication.shared.canOpenURL(url) {
      return true
    }
    let testPath = "/private/jb_test.txt"
    do {
      try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: testPath)
      return true
    } catch {
      return false
    }
#endif
  }

  private func carrierName() -> String {
    let networkInfo = CTTelephonyNetworkInfo()
    if #available(iOS 12.0, *) {
      return networkInfo.serviceSubscriberCellularProviders?.values.first?.carrierName ?? ""
    }
    return networkInfo.subscriberCellularProvider?.carrierName ?? ""
  }

  private func currentNetworkType() -> String {
    if #available(iOS 12.0, *) {
      let info = CTTelephonyNetworkInfo()
      if let radioTech = info.serviceCurrentRadioAccessTechnology?.values.first {
        return mapRadioTech(radioTech)
      }
    } else {
      let info = CTTelephonyNetworkInfo()
      if let radioTech = info.currentRadioAccessTechnology {
        return mapRadioTech(radioTech)
      }
    }
    return "WIFI"
  }

  private func mapRadioTech(_ tech: String) -> String {
    switch tech {
    case CTRadioAccessTechnologyGPRS,
         CTRadioAccessTechnologyEdge,
         CTRadioAccessTechnologyCDMA1x:
      return "2G"
    case CTRadioAccessTechnologyWCDMA,
         CTRadioAccessTechnologyHSDPA,
         CTRadioAccessTechnologyHSUPA,
         CTRadioAccessTechnologyCDMAEVDORev0,
         CTRadioAccessTechnologyCDMAEVDORevA,
         CTRadioAccessTechnologyCDMAEVDORevB,
         CTRadioAccessTechnologyeHRPD:
      return "3G"
    case CTRadioAccessTechnologyLTE:
      return "4G"
    default:
      break
    }
    if #available(iOS 14.1, *) {
      if tech == CTRadioAccessTechnologyNR || tech == CTRadioAccessTechnologyNRNSA {
        return "5G"
      }
    }
    return "OTHER"
  }

  private func wifiInfo(result: @escaping FlutterResult) {
    let ip = wifiIPv4Address()
    fetchCurrentSSIDBSSID { ssid, bssid in
      result([
        "ip": ip,
        "ssid": ssid,
        "bssid": bssid,
        "wifiCount": ssid.isEmpty ? 0 : 1,
      ])
    }
  }

  private func fetchCurrentSSIDBSSID(completion: @escaping (String, String) -> Void) {
    if #available(iOS 26.0, *) {
      NEHotspotNetwork.fetchCurrent { [weak self] network in
        let ssid = network?.ssid ?? ""
        let bssid = network?.bssid ?? ""
        if !ssid.isEmpty || !bssid.isEmpty {
          completion(ssid, bssid)
          return
        }
        let fallback = self?.legacySSIDBSSID() ?? ("", "")
        completion(fallback.0, fallback.1)
      }
      return
    }
    let fallback = legacySSIDBSSID()
    completion(fallback.0, fallback.1)
  }

  private func legacySSIDBSSID() -> (String, String) {
    var ssid = ""
    var bssid = ""
    if let interfaces = CNCopySupportedInterfaces() as? [String] {
      for interface in interfaces {
        if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
          ssid = info[kCNNetworkInfoKeySSID as String] as? String ?? ""
          bssid = info[kCNNetworkInfoKeyBSSID as String] as? String ?? ""
          if !ssid.isEmpty || !bssid.isEmpty {
            break
          }
        }
      }
    }
    return (ssid, bssid)
  }

  private func wifiIPv4Address() -> String {
    var address = ""
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    if getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr {
      var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
      while ptr != nil {
        let interface = ptr!.pointee
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) {
          let name = String(cString: interface.ifa_name)
          if name == "en0" {
            var addr = interface.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
              &addr,
              socklen_t(interface.ifa_addr.pointee.sa_len),
              &hostname,
              socklen_t(hostname.count),
              nil,
              0,
              NI_NUMERICHOST
            ) == 0 {
              address = String(cString: hostname)
              break
            }
          }
        }
        ptr = interface.ifa_next
      }
      freeifaddrs(ifaddr)
    }
    return address
  }

  private func storageInfo() -> [String: String] {
    let documentPath = NSSearchPathForDirectoriesInDomains(
      .documentDirectory,
      .userDomainMask,
      true
    ).first ?? NSHomeDirectory()
    let attrs = (try? FileManager.default.attributesOfFileSystem(forPath: documentPath)) ?? [:]
    let freeDisk = attrs[.systemFreeSize] as? UInt64 ?? 0
    let totalDisk = attrs[.systemSize] as? UInt64 ?? 0
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    var vmStats = vm_statistics_data_t()
    var infoCount = mach_msg_type_number_t(
      MemoryLayout<vm_statistics>.size / MemoryLayout<integer_t>.size
    )
    let status = withUnsafeMutableBytes(of: &vmStats) {
      let boundBuffer = $0.bindMemory(to: Int32.self)
      return host_statistics(
        mach_host_self(),
        HOST_VM_INFO,
        boundBuffer.baseAddress,
        &infoCount
      )
    }
    let freeMemory: UInt64
    if status == KERN_SUCCESS {
      freeMemory = UInt64(vm_page_size) * UInt64(vmStats.free_count)
    } else {
      freeMemory = 0
    }
    return [
      "flung": "\(freeDisk)",
      "university": "\(totalDisk)",
      "overbrowsed": "\(totalMemory)",
      "gonfalons": "\(freeMemory)",
    ]
  }

  private func locationStatusString() -> String {
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager?.authorizationStatus ?? CLLocationManager.authorizationStatus()
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      return "granted"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "notDetermined"
    @unknown default:
      return "denied"
    }
  }

  private func currentScreenInches() -> String {
    let nativeBounds = UIScreen.main.nativeBounds
    let width = min(nativeBounds.width, nativeBounds.height)
    let height = max(nativeBounds.width, nativeBounds.height)
    let ppi = screenPPI(width: width, height: height)
    if ppi <= 0 {
      return ""
    }
    let diagonal = sqrt(width * width + height * height)
    return String(format: "%.1f", diagonal / ppi)
  }

  private func screenPPI(width: CGFloat, height: CGFloat) -> CGFloat {
    let w = Int(width.rounded())
    let h = Int(height.rounded())
    switch (w, h) {
    case (640, 960), (640, 1136), (750, 1334), (828, 1792):
      return 326
    case (1080, 1920):
      return 401
    case (1125, 2436), (1242, 2688), (1284, 2778):
      return 458
    case (1170, 2532), (1179, 2556), (1290, 2796), (1320, 2868):
      return 460
    case (1488, 2266):
      return 326
    case (1536, 2048), (1620, 2160), (1668, 2224), (1668, 2388), (2048, 2732):
      return 264
    default:
      if UIDevice.current.userInterfaceIdiom == .pad {
        return UIScreen.main.nativeScale >= 2.0 ? 264 : 132
      }
      let scale = UIScreen.main.nativeScale
      if scale >= 3.0 {
        if w <= 1080 {
          return 401
        }
        if w >= 1179 {
          return 460
        }
        return 458
      }
      return scale >= 2.0 ? 326 : 163
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

final class FunnyLoanDeviceTools {
  static let shared = FunnyLoanDeviceTools()

  private let keychainService = "com.funny_loan.device"
  private let idfvAccount = "funny_loan.idfv"
  private var trackingActiveObserver: NSObjectProtocol?

  private init() {}

  func getIdfv() -> String {
    if let stored = keychainRead(account: idfvAccount), !stored.isEmpty {
      return stored
    }
    let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
    if !idfv.isEmpty {
      keychainSave(account: idfvAccount, value: idfv)
    }
    return idfv
  }

  func getIdfa() -> String {
#if targetEnvironment(simulator)
    return ""
#else
    if #available(iOS 14, *) {
      guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
        return ""
      }
      return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
      return ""
    }
    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
#endif
  }

  func requestIdfa(completion: @escaping (String, String) -> Void) {
#if targetEnvironment(simulator)
    DispatchQueue.main.async {
      completion("", "not_supported")
    }
#else
    DispatchQueue.main.async {
      if #available(iOS 14, *) {
        let status = ATTrackingManager.trackingAuthorizationStatus
        if status != .notDetermined {
          completion(self.getIdfa(), self.trackingStatusString(status))
          return
        }
        self.requestTrackingWhenAppActive {
          ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
              completion(self.getIdfa(), self.trackingStatusString(status))
            }
          }
        }
        return
      }
      completion(self.getIdfa(), "authorized")
    }
#endif
  }

  func currentTrackingStatusString() -> String {
#if targetEnvironment(simulator)
    return "not_supported"
#else
    if #available(iOS 14, *) {
      return trackingStatusString(ATTrackingManager.trackingAuthorizationStatus)
    }
    return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
      ? "authorized"
      : "denied"
#endif
  }

  @available(iOS 14, *)
  private func trackingStatusString(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .authorized:
      return "authorized"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "not_determined"
    @unknown default:
      return "denied"
    }
  }

  @available(iOS 14, *)
  private func requestTrackingWhenAppActive(_ action: @escaping () -> Void) {
    if UIApplication.shared.applicationState == .active {
      action()
      return
    }
    if let observer = trackingActiveObserver {
      NotificationCenter.default.removeObserver(observer)
      trackingActiveObserver = nil
    }
    trackingActiveObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      if let observer = self.trackingActiveObserver {
        NotificationCenter.default.removeObserver(observer)
        self.trackingActiveObserver = nil
      }
      action()
    }
  }

  private func keychainSave(account: String, value: String) {
    let data = Data(value.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
    let attributes = query.merging(
      [kSecValueData as String: data],
      uniquingKeysWith: { $1 }
    )
    SecItemAdd(attributes as CFDictionary, nil)
  }

  private func keychainRead(account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
}
