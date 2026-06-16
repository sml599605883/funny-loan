import 'dart:async';
import 'dart:developer';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_session_failure.dart';
import 'package:adjust_sdk/adjust_session_success.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/native/native_bridge.dart';
import '../core/permissions/app_permission_service.dart';
import '../core/storage/app_data_store.dart';
import '../network/api/api_service.dart';
import 'report_location_info.dart';
import 'report_payload_builder.dart';

class ReportIosIdentifiers {
  const ReportIosIdentifiers({required this.idfv, required this.idfa});

  final String idfv;
  final String idfa;

  bool get isEmpty => idfv.isEmpty && idfa.isEmpty;

  String get signature => '$idfv|$idfa';
}

abstract class ReportApiClient {
  Future<void> reportLocation(Map<String, dynamic> body);

  Future<Map<String, dynamic>> reportGoogleMarket(Map<String, dynamic> body);

  Future<void> reportRiskEvent(Map<String, dynamic> body);

  Future<void> reportEncryptedDeviceInfo(String plainText);

  Future<void> reportApplePushToken(Map<String, dynamic> body);

  Future<void> reportFaceRecognitionResult(Map<String, dynamic> body);
}

abstract class ReportNativeDataSource {
  Stream<String> get pushTokenChanges;

  Stream<String> get trackingAuthorizationChanges;

  Future<ReportIosIdentifiers> getIosIdentifiers();

  Future<ReportLocationInfo?> getCurrentLocation();

  Future<bool> isLocationPermissionNotDetermined();

  Future<String> getPushToken();

  Future<Map<String, dynamic>> getBatteryInfo();

  Future<int> getElapsedRealtime();

  Future<int> getUptimeMillis();

  Future<int> getProxyEnabled();

  Future<int> getVpnEnabled();

  Future<int> getRooted();

  Future<int> getIsEmulator();

  Future<String> getDeviceLanguage();

  Future<String> getCarrierName();

  Future<String> getNetworkType();

  Future<String> getTimeZoneId();

  Future<int> getCpuCores();

  Future<String> getDeviceName();

  Future<String> getScreenInches();

  Future<Map<String, dynamic>> getWifiInfo();

  Future<Map<String, dynamic>> getDeviceStorageInfo();
}

abstract class ReportCache {
  bool get hasOpenedApp;
  set hasOpenedApp(bool value);

  int? get loginTime;
  set loginTime(int? value);

  bool get attributionInitialized;
  set attributionInitialized(bool value);

  Map<String, dynamic>? get locationInfo;
  set locationInfo(Map<String, dynamic>? value);

  String? get lastApplePushToken;
  set lastApplePushToken(String? value);

  bool get isLoggedIn;
}

class ReportRiskScene {
  const ReportRiskScene._();

  static const loginSuccess = '1';
  static const identityUploadEnter = '2';
  static const identitySaveSuccess = '3';
  static const faceUploadSuccess = '4';
  static const personalInfoSaveSuccess = '5';
  static const workInfoSaveSuccess = '6';
  static const contactInfoSaveSuccess = '7';
  static const bindCardSuccess = '8';
  static const orderConfirm = '9';
  static const webViewRisk = '10';
}

abstract class ReportAttributionInitializer {
  Future<void> initialize(String token);
}

abstract class ReportPermissionRequester {
  Future<void> requestNotification();

  Future<void> requestTracking();
}

class ReportManager {
  ReportManager({
    ReportApiClient? api,
    ReportNativeDataSource? native,
    ReportCache? cache,
    ReportAttributionInitializer? attributionInitializer,
    ReportPermissionRequester? permissionRequester,
    this.payloadBuilder = const ReportPayloadBuilder(),
    Future<void> Function()? waitForResumedFrame,
    this.permissionThrottleDelay = const Duration(milliseconds: 350),
    this.locationTimeout = const Duration(seconds: 3),
    this.pushTokenWaitTimeout = const Duration(seconds: 5),
  }) : api = api ?? GetReportApiClient(),
       native = native ?? MethodChannelReportNativeDataSource(),
       cache = cache ?? AppDataStoreReportCache(),
       attributionInitializer =
           attributionInitializer ?? const AdjustReportAttributionInitializer(),
       permissionRequester =
           permissionRequester ?? const AppReportPermissionRequester(),
       _waitForResumedFrame =
           waitForResumedFrame ?? _defaultWaitForResumedFrame;

  final ReportApiClient api;
  final ReportNativeDataSource native;
  final ReportCache cache;
  final ReportAttributionInitializer attributionInitializer;
  final ReportPermissionRequester permissionRequester;
  final ReportPayloadBuilder payloadBuilder;
  final Future<void> Function() _waitForResumedFrame;
  final Duration permissionThrottleDelay;
  final Duration locationTimeout;
  final Duration pushTokenWaitTimeout;

  bool _didStart = false;
  bool _isReportingMarket = false;
  bool _isRequestingStartupPermissions = false;
  bool _isRequestingResumePermissions = false;
  bool _isListeningForPushToken = false;
  bool _isListeningForFirstTrackingResult = false;
  bool isRequestingForegroundPermission = false;
  String? _lastMarketSignature;
  String? _reportingPushToken;
  Future<ReportLocationInfo?>? _pendingLocationFuture;
  StreamSubscription<String>? _pushTokenSubscription;
  StreamSubscription<String>? _trackingSubscription;

  Future<void> onAppStarted() async {
    if (_didStart) {
      return;
    }
    _didStart = true;
    final isFirstLaunch = !cache.hasOpenedApp;
    cache.hasOpenedApp = true;

    if (isFirstLaunch) {
      _listenForFirstTrackingResult();
    }

    startPushTokenListener();
    await _runNonBlocking('startup permissions', _requestStartupPermissions);
    await _runNonBlocking('startup location', reportLocationFromNative);
    if (!isFirstLaunch) {
      await _runNonBlocking('startup google market', reportGoogleMarket);
    }
    await _runNonBlocking('startup push token', uploadApplePushToken);
  }

  Future<void> onAppResumed() async {
    if (_isRequestingResumePermissions) {
      return;
    }
    _isRequestingResumePermissions = true;
    try {
      await _waitForResumedFrame();
      await _requestForegroundPermission(permissionRequester.requestTracking);
      await Future<void>.delayed(permissionThrottleDelay);
      await reportGoogleMarket();
    } finally {
      _isRequestingResumePermissions = false;
    }
  }

  Future<void> onLoginSuccess({int? nowMillis}) async {
    cache.loginTime = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    await _runNonBlocking('login location', reportLocationFromNative);
    await _runNonBlocking('login push token', uploadApplePushToken);
  }

  Future<ReportLocationInfo?> fetchNativeLocationInfo() {
    final pending = _pendingLocationFuture;
    if (pending != null) {
      return pending;
    }

    final future = native
        .getCurrentLocation()
        .then((info) {
          if (info != null && info.isValid) {
            cache.locationInfo = info.toDeviceCache();
          }
          return info;
        })
        .catchError((Object error, StackTrace stackTrace) {
          _logReportError('native location', error, stackTrace);
          return null;
        })
        .whenComplete(() {
          _pendingLocationFuture = null;
        });
    _pendingLocationFuture = future;
    return future;
  }

  Future<void> reportLocationFromNative() async {
    if (!cache.isLoggedIn) {
      return;
    }
    final location = await fetchNativeLocationInfo();
    final isLocationNotDetermined = await native
        .isLocationPermissionNotDetermined();
    if (!isLocationNotDetermined) {
      unawaited(
        _runNonBlocking('device info after location', reportDeviceInfo),
      );
    }
    if (location == null) {
      return;
    }
    unawaited(_runNonBlocking('device info after location', reportDeviceInfo));
    await api.reportLocation(location.toLocationReportBody());
  }

  Future<void> reportGoogleMarket() async {
    final identifiers = await native.getIosIdentifiers();
    final signature = identifiers.signature;
    if (identifiers.isEmpty ||
        signature == _lastMarketSignature ||
        _isReportingMarket) {
      return;
    }
    _isReportingMarket = true;
    try {
      final response = await api.reportGoogleMarket(<String, dynamic>{
        'typescripts': identifiers.idfv,
        'overtired': identifiers.idfa,
      });
      _lastMarketSignature = signature;
      final token = _text(response['disorder']);
      if (token.isNotEmpty && !cache.attributionInitialized) {
        await attributionInitializer.initialize(token);
        cache.attributionInitialized = true;
      }
    } catch (error, stackTrace) {
      _logReportError('google market', error, stackTrace);
    } finally {
      _isReportingMarket = false;
    }
  }

  Future<void> reportRiskEvent(Map<String, dynamic> body) async {
    await _runNonBlocking('risk event', () => api.reportRiskEvent(body));
  }

  Future<void> reportRiskEventWithLocation({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String startTime,
    int? nowMillis,
  }) async {
    final normalizedStartTime = startTime.trim();
    if (normalizedStartTime.isEmpty) {
      throw ArgumentError.value(startTime, 'startTime', 'must not be empty');
    }
    final currentSeconds =
        ((nowMillis ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000)
            .toString();
    final identifiers = await native.getIosIdentifiers();
    final location = await _locationWithCacheFallback();
    final body = payloadBuilder.buildRiskPayload(
      productId: productId,
      sceneType: sceneType,
      orderNo: orderNo,
      startTime: normalizedStartTime,
      endTime: currentSeconds,
      identifiers: identifiers,
      location: location,
    );
    await reportRiskEvent(body);
  }

  Future<void> reportRiskScene({
    required String sceneType,
    String productId = '',
    String orderNo = '',
    required String startTime,
    int? nowMillis,
  }) async {
    await reportRiskEventWithLocation(
      productId: productId,
      sceneType: sceneType,
      orderNo: orderNo,
      startTime: startTime,
      nowMillis: nowMillis,
    );
  }

  Future<void> reportDeviceInfo() async {
    if (!cache.isLoggedIn) {
      return;
    }
    final location = await _locationWithCacheFallback();
    final plainText = await payloadBuilder.buildDevicePayload(
      native: native,
      cache: cache,
      location: location,
    );
    await _runNonBlocking(
      'device info',
      () => api.reportEncryptedDeviceInfo(plainText),
    );
  }

  Future<void> uploadApplePushToken() async {
    startPushTokenListener();
    final directToken = _text(await native.getPushToken());
    var token = directToken;
    if (token.isEmpty) {
      token = await _waitForPushToken();
    }
    await _reportPushToken(token);
  }

  void startPushTokenListener() {
    if (_isListeningForPushToken) {
      return;
    }
    _isListeningForPushToken = true;
    _pushTokenSubscription = native.pushTokenChanges.listen((token) {
      unawaited(_reportPushToken(token));
    });
  }

  Future<void> reportFaceRecognitionResult({
    required String livenessId,
    required String requestId,
    required String resultCode,
    required String result,
  }) async {
    await _runNonBlocking(
      'face recognition result',
      () => api.reportFaceRecognitionResult(<String, dynamic>{
        'aroynted': _text(livenessId),
        'pyrogenicity': _text(requestId),
        'grayly': _text(resultCode),
        'cithrens': _text(result),
      }),
    );
  }

  Future<void> dispose() async {
    await _pushTokenSubscription?.cancel();
    await _trackingSubscription?.cancel();
  }

  void _listenForFirstTrackingResult() {
    if (_isListeningForFirstTrackingResult) {
      return;
    }
    _isListeningForFirstTrackingResult = true;
    _trackingSubscription = native.trackingAuthorizationChanges.listen((
      status,
    ) {
      final normalized = _text(status).toLowerCase();
      if (normalized.isEmpty ||
          normalized == 'not_supported' ||
          normalized == 'not_determined') {
        return;
      }
      unawaited(_trackingSubscription?.cancel());
      _trackingSubscription = null;
      _isListeningForFirstTrackingResult = false;
      unawaited(reportGoogleMarket());
    });
  }

  Future<void> _requestStartupPermissions() async {
    if (_isRequestingStartupPermissions) {
      return;
    }
    _isRequestingStartupPermissions = true;
    try {
      await _waitForResumedFrame();
      await _requestForegroundPermission(
        permissionRequester.requestNotification,
      );
      await Future<void>.delayed(permissionThrottleDelay);
      await _requestForegroundPermission(permissionRequester.requestTracking);
    } finally {
      _isRequestingStartupPermissions = false;
    }
  }

  Future<void> _requestForegroundPermission(
    Future<void> Function() request,
  ) async {
    isRequestingForegroundPermission = true;
    try {
      await request();
    } finally {
      isRequestingForegroundPermission = false;
    }
  }

  Future<ReportLocationInfo?> _locationWithCacheFallback() async {
    try {
      final liveLocation = await fetchNativeLocationInfo().timeout(
        locationTimeout,
        onTimeout: () => null,
      );
      if (liveLocation != null) {
        return liveLocation;
      }
    } catch (error, stackTrace) {
      _logReportError('location fallback', error, stackTrace);
    }
    return ReportLocationInfo.fromCache(cache.locationInfo);
  }

  Future<String> _waitForPushToken() async {
    try {
      return await native.pushTokenChanges
          .map(_text)
          .firstWhere((token) => token.isNotEmpty)
          .timeout(pushTokenWaitTimeout);
    } catch (_) {
      return '';
    }
  }

  Future<void> _reportPushToken(String rawToken) async {
    final token = _text(rawToken);
    if (token.isEmpty ||
        token == cache.lastApplePushToken ||
        token == _reportingPushToken) {
      return;
    }
    _reportingPushToken = token;
    try {
      await api.reportApplePushToken(<String, dynamic>{'outvaluing': token});
      cache.lastApplePushToken = token;
    } catch (error, stackTrace) {
      _logReportError('apple push token', error, stackTrace);
    } finally {
      _reportingPushToken = null;
    }
  }

  Future<void> _runNonBlocking(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _logReportError(label, error, stackTrace);
    }
  }

  static Future<void> _defaultWaitForResumedFrame() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    await completer.future;
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static void _logReportError(
    String label,
    Object error,
    StackTrace stackTrace,
  ) {
    log('Report $label failed: $error', stackTrace: stackTrace);
  }
}

class GetReportApiClient implements ReportApiClient {
  ApiService? get _apiService =>
      Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null;

  @override
  Future<void> reportLocation(Map<String, dynamic> body) async {
    await _apiService?.reportLocation(body);
  }

  @override
  Future<Map<String, dynamic>> reportGoogleMarket(
    Map<String, dynamic> body,
  ) async {
    final response = await _apiService?.reportGoogleMarket(body);
    return response?.data.mapValue ?? const <String, dynamic>{};
  }

  @override
  Future<void> reportRiskEvent(Map<String, dynamic> body) async {
    await _apiService?.reportRiskEvent(body);
  }

  @override
  Future<void> reportEncryptedDeviceInfo(String plainText) async {
    await _apiService?.reportEncryptedDeviceInfo(plainText: plainText);
  }

  @override
  Future<void> reportApplePushToken(Map<String, dynamic> body) async {
    await _apiService?.reportApplePushToken(body);
  }

  @override
  Future<void> reportFaceRecognitionResult(Map<String, dynamic> body) async {
    await _apiService?.reportTongdun(body);
  }
}

class MethodChannelReportNativeDataSource implements ReportNativeDataSource {
  @override
  Stream<String> get pushTokenChanges => NativeBridge.pushTokenChanges;

  @override
  Stream<String> get trackingAuthorizationChanges =>
      NativeBridge.trackingAuthorizationChanges;

  @override
  Future<ReportIosIdentifiers> getIosIdentifiers() async {
    final map = await NativeBridge.getIosIdentifiers();
    return ReportIosIdentifiers(
      idfv: _text(map['idfv']),
      idfa: _text(map['idfa']),
    );
  }

  @override
  Future<ReportLocationInfo?> getCurrentLocation() async {
    return ReportLocationInfo.fromNativeMap(
      await NativeBridge.getCurrentLocation(),
    );
  }

  @override
  Future<bool> isLocationPermissionNotDetermined() {
    return NativeBridge.isLocationPermissionNotDetermined();
  }

  @override
  Future<String> getPushToken() => NativeBridge.getPushToken();

  @override
  Future<Map<String, dynamic>> getBatteryInfo() =>
      NativeBridge.getBatteryInfo();

  @override
  Future<int> getElapsedRealtime() => NativeBridge.getDeviceElapsedRealtime();

  @override
  Future<int> getUptimeMillis() => NativeBridge.getDeviceUptime();

  @override
  Future<int> getProxyEnabled() => NativeBridge.getProxyEnabled();

  @override
  Future<int> getVpnEnabled() => NativeBridge.getVpnEnabled();

  @override
  Future<int> getRooted() => NativeBridge.getRooted();

  @override
  Future<int> getIsEmulator() => NativeBridge.getIsEmulator();

  @override
  Future<String> getDeviceLanguage() => NativeBridge.getDeviceLanguage();

  @override
  Future<String> getCarrierName() => NativeBridge.getCarrierName();

  @override
  Future<String> getNetworkType() => NativeBridge.getNetworkType();

  @override
  Future<String> getTimeZoneId() => NativeBridge.getTimeZoneId();

  @override
  Future<int> getCpuCores() => NativeBridge.getCpuCores();

  @override
  Future<String> getDeviceName() => NativeBridge.getDeviceName();

  @override
  Future<String> getScreenInches() => NativeBridge.getScreenInches();

  @override
  Future<Map<String, dynamic>> getWifiInfo() => NativeBridge.getWifiInfo();

  @override
  Future<Map<String, dynamic>> getDeviceStorageInfo() {
    return NativeBridge.getDeviceStorageInfo();
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}

class AppDataStoreReportCache implements ReportCache {
  static const _openedAppKey = 'report_opened_app';
  static const _loginTimeKey = 'report_login_time';
  static const _attributionInitializedKey = 'report_attribution_initialized';
  static const _locationInfoKey = 'report_location_info';
  static const _lastApplePushTokenKey = 'report_last_apple_push_token';

  @override
  bool get hasOpenedApp =>
      AppDataStore.getPersistentBool(_openedAppKey) ?? false;

  @override
  set hasOpenedApp(bool value) {
    unawaited(AppDataStore.setPersistentBool(_openedAppKey, value));
  }

  @override
  int? get loginTime => AppDataStore.getPersistentInt(_loginTimeKey);

  @override
  set loginTime(int? value) {
    if (value == null) {
      unawaited(AppDataStore.removePersistent(_loginTimeKey));
      return;
    }
    unawaited(AppDataStore.setPersistentInt(_loginTimeKey, value));
  }

  @override
  bool get attributionInitialized =>
      AppDataStore.getPersistentBool(_attributionInitializedKey) ?? false;

  @override
  set attributionInitialized(bool value) {
    unawaited(
      AppDataStore.setPersistentBool(_attributionInitializedKey, value),
    );
  }

  @override
  Map<String, dynamic>? get locationInfo =>
      AppDataStore.getPersistentJson(_locationInfoKey);

  @override
  set locationInfo(Map<String, dynamic>? value) {
    if (value == null || value.isEmpty) {
      unawaited(AppDataStore.removePersistent(_locationInfoKey));
      return;
    }
    unawaited(AppDataStore.setPersistentJson(_locationInfoKey, value));
  }

  @override
  String? get lastApplePushToken =>
      AppDataStore.getPersistentString(_lastApplePushTokenKey);

  @override
  set lastApplePushToken(String? value) {
    final token = value?.trim() ?? '';
    if (token.isEmpty) {
      unawaited(AppDataStore.removePersistent(_lastApplePushTokenKey));
      return;
    }
    unawaited(AppDataStore.setPersistentString(_lastApplePushTokenKey, token));
  }

  @override
  bool get isLoggedIn =>
      (AppDataStore.getPersistentString(AppDataStore.persistedTokenKey) ?? '')
          .trim()
          .isNotEmpty;
}

class AppReportPermissionRequester implements ReportPermissionRequester {
  const AppReportPermissionRequester();

  @override
  Future<void> requestNotification() async {
    await AppPermissionService.requestNotification();
  }

  @override
  Future<void> requestTracking() async {
    await NativeBridge.requestTrackingPermission();
  }
}

class AdjustReportAttributionInitializer
    implements ReportAttributionInitializer {
  const AdjustReportAttributionInitializer({
    this.initSdk = Adjust.initSdk,
    this.onSessionSuccess,
    this.onSessionFailure,
  });

  final void Function(AdjustConfig config) initSdk;
  final void Function(AdjustSessionSuccess success)? onSessionSuccess;
  final void Function(AdjustSessionFailure failure)? onSessionFailure;

  @override
  Future<void> initialize(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return;
    }
    final config = AdjustConfig(normalizedToken, AdjustEnvironment.production);
    config.isSendingInBackgroundEnabled = true;
    config.sessionSuccessCallback = (success) {
      onSessionSuccess?.call(success);
    };
    config.sessionFailureCallback = (failure) {
      onSessionFailure?.call(failure);
    };
    initSdk(config);
  }
}
