import 'dart:async';

import 'package:flutter/services.dart';

import '../json/json.dart';

class ProxySettings {
  const ProxySettings({
    required this.host,
    required this.port,
    required this.isEnabled,
  });

  final String host;
  final int port;
  final bool isEnabled;

  bool get isValid => isEnabled && host.isNotEmpty && port > 0;
}

class TrustDecisionLivenessResult {
  const TrustDecisionLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.sequenceId,
    required this.livenessId,
    required this.raw,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String sequenceId;
  final String livenessId;
  final Map<String, dynamic> raw;
}

abstract class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'funny_loan/native_bridge',
  );
  static final StreamController<String> _pushTokenController =
      StreamController<String>.broadcast();
  static final StreamController<String> _trackingAuthorizationController =
      StreamController<String>.broadcast();
  static bool _methodHandlerBound = false;

  static Stream<String> get pushTokenChanges {
    _bindNativeEventHandlers();
    return _pushTokenController.stream;
  }

  static Stream<String> get trackingAuthorizationChanges {
    _bindNativeEventHandlers();
    return _trackingAuthorizationController.stream;
  }

  static void _bindNativeEventHandlers() {
    if (_methodHandlerBound) {
      return;
    }
    _methodHandlerBound = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPushTokenChanged':
          final token = _stringFromNativeArguments(call.arguments);
          if (token.isNotEmpty) {
            _pushTokenController.add(token);
          }
          return null;
        case 'onTrackingAuthorizationChanged':
          final status = _stringFromNativeArguments(call.arguments);
          _trackingAuthorizationController.add(status);
          return null;
        default:
          return null;
      }
    });
  }

  static String _stringFromNativeArguments(Object? arguments) {
    if (arguments is String) {
      return arguments.trim();
    }
    if (arguments is Map) {
      return (arguments['value'] ?? arguments['token'] ?? arguments['status'])
          .toString()
          .trim();
    }
    return '';
  }

  static Future<Map<String, dynamic>?> invokeMapMethod(String method) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(method);
    if (result == null) {
      return null;
    }
    return Map<String, dynamic>.from(result);
  }

  static Future<ProxySettings?> getSystemProxy() async {
    final result = await invokeMapMethod('getSystemProxy');
    if (result == null) {
      return null;
    }

    final host = result['host'] as String? ?? '';
    final enabled = result['enabled'] as bool? ?? false;
    final portValue = result['port'];
    final port = switch (portValue) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    final settings = ProxySettings(host: host, port: port, isEnabled: enabled);
    return settings.isValid ? settings : null;
  }

  static Future<Map<String, dynamic>> getIosIdentifiers() async {
    try {
      final result = await invokeMapMethod('getIosIdentifiers');
      return result ?? const <String, dynamic>{};
    } on PlatformException {
      return const <String, dynamic>{};
    } on MissingPluginException {
      return const <String, dynamic>{};
    }
  }

  static Future<String> requestTrackingPermission() async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'requestTrackingPermission',
      );
      return result?.toString().trim() ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  static Future<bool> isLocationPermissionNotDetermined() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isLocationPermissionNotDetermined',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<String> getPushToken() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getPushToken');
      return result?.toString().trim() ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }

  static Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final result = await invokeMapMethod('getBatteryInfo');
      return result ?? const <String, dynamic>{};
    } on PlatformException {
      return const <String, dynamic>{};
    } on MissingPluginException {
      return const <String, dynamic>{};
    }
  }

  static Future<int> getDeviceUptime() {
    return _invokeIntMethod('getDeviceUptime');
  }

  static Future<int> getDeviceElapsedRealtime() {
    return _invokeIntMethod('getDeviceElapsedRealtime');
  }

  static Future<int> getProxyEnabled() {
    return _invokeIntMethod('getProxyEnabled');
  }

  static Future<int> getVpnEnabled() {
    return _invokeIntMethod('getVpnEnabled');
  }

  static Future<int> getRooted() {
    return _invokeIntMethod('getRooted');
  }

  static Future<int> getIsEmulator() {
    return _invokeIntMethod('getIsEmulator');
  }

  static Future<String> getDeviceLanguage() {
    return _invokeStringMethod('getDeviceLanguage');
  }

  static Future<String> getCarrierName() {
    return _invokeStringMethod('getCarrierName');
  }

  static Future<String> getNetworkType() {
    return _invokeStringMethod('getNetworkType', fallback: 'OTHER');
  }

  static Future<String> getTimeZoneId() {
    return _invokeStringMethod('getTimeZoneId');
  }

  static Future<int> getCpuCores() {
    return _invokeIntMethod('getCpuCores');
  }

  static Future<String> getDeviceName() {
    return _invokeStringMethod('getDeviceName');
  }

  static Future<String> getScreenInches() {
    return _invokeStringMethod('getScreenInches');
  }

  static Future<Map<String, dynamic>> getWifiInfo() async {
    try {
      final result = await invokeMapMethod('getWifiInfo');
      return result ??
          const <String, dynamic>{
            'ip': '',
            'ssid': '',
            'bssid': '',
            'wifiCount': 0,
          };
    } on PlatformException {
      return const <String, dynamic>{
        'ip': '',
        'ssid': '',
        'bssid': '',
        'wifiCount': 0,
      };
    } on MissingPluginException {
      return const <String, dynamic>{
        'ip': '',
        'ssid': '',
        'bssid': '',
        'wifiCount': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getDeviceStorageInfo() async {
    try {
      final result = await invokeMapMethod('getDeviceStorageInfo');
      return result ??
          const <String, dynamic>{
            'flung': '',
            'university': '',
            'overbrowsed': '',
            'gonfalons': '',
          };
    } on PlatformException {
      return const <String, dynamic>{
        'flung': '',
        'university': '',
        'overbrowsed': '',
        'gonfalons': '',
      };
    } on MissingPluginException {
      return const <String, dynamic>{
        'flung': '',
        'university': '',
        'overbrowsed': '',
        'gonfalons': '',
      };
    }
  }

  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      return await invokeMapMethod('getCurrentLocation');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<TrustDecisionLivenessResult> showTrustDecisionLiveness(
    String unwarned,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'showTrustDecisionLiveness',
        unwarned,
      );
      if (result == null) {
        return const TrustDecisionLivenessResult(
          success: false,
          code: -1,
          message: 'Liveness returned no result',
          image: '',
          sequenceId: '',
          livenessId: '',
          raw: <String, dynamic>{},
        );
      }

      final json = Json(result);
      final rawValue = json['raw'].rawValue;
      return TrustDecisionLivenessResult(
        success: json['success'].boolOrNull ?? false,
        code: json['code'].intOrNull ?? -1,
        message: json['message'].stringValue,
        image: json['image'].stringValue,
        sequenceId: json['sequence_id'].stringValue,
        livenessId: json['liveness_id'].stringValue,
        raw: rawValue is Map ? Map<String, dynamic>.from(rawValue) : const {},
      );
    } on PlatformException catch (error) {
      return TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Failed to start liveness verification',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{
          'code': error.code,
          if (error.details != null) 'details': error.details,
        },
      );
    }
  }

  static Future<bool> requestAppReview() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAppReview');
      return result ?? true;
    } on PlatformException {
      return false;
    }
  }

  static Future<int> _invokeIntMethod(String method) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(method);
      if (result is int) {
        return result;
      }
      if (result is num) {
        return result.toInt();
      }
      if (result is String) {
        return int.tryParse(result.trim()) ?? 0;
      }
      return 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  static Future<String> _invokeStringMethod(
    String method, {
    String fallback = '',
  }) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(method);
      final value = result?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    } on PlatformException {
      return fallback;
    } on MissingPluginException {
      return fallback;
    }
  }
}
