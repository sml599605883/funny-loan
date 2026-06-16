import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'report_location_info.dart';
import 'report_manager.dart';

class ReportPayloadBuilder {
  const ReportPayloadBuilder();

  Map<String, dynamic> buildRiskPayload({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String startTime,
    required String endTime,
    required ReportIosIdentifiers identifiers,
    required ReportLocationInfo? location,
  }) {
    return <String, dynamic>{
      'skoals': _text(productId),
      'nonslip': _text(sceneType),
      'rejectee': _text(orderNo),
      'typescripts': identifiers.idfv,
      'overtired': identifiers.idfa,
      'kenaf': _text(startTime),
      'portaged': _text(endTime),
      'shebang': location?.longitude ?? '',
      'dogedom': location?.latitude ?? '',
    };
  }

  Future<String> buildDevicePayload({
    required ReportNativeDataSource native,
    required ReportCache cache,
    required ReportLocationInfo? location,
  }) async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await _packageInfo();
    final iosInfo = Platform.isIOS ? await deviceInfo.iosInfo : null;
    final androidInfo = Platform.isAndroid
        ? await deviceInfo.androidInfo
        : null;
    final identifiers = await native.getIosIdentifiers();
    final batteryInfo = await native.getBatteryInfo();
    final elapsed = await native.getElapsedRealtime();
    final uptime = await native.getUptimeMillis();
    final wifiInfo = await native.getWifiInfo();
    final storageInfo = await native.getDeviceStorageInfo();
    final locationCache = location?.toDeviceCache() ?? cache.locationInfo;

    final payload = <String, dynamic>{
      'buckthorn': Platform.operatingSystem,
      'caribou': iosInfo?.systemVersion ?? androidInfo?.version.release ?? '',
      'cembalists': cache.loginTime ?? 0,
      'rabidly': packageInfo.packageName,
      'waffle': <String, dynamic>{
        'scow': batteryInfo['scow'] ?? batteryInfo['dayroom'] ?? '',
        'structuration':
            batteryInfo['structuration'] ?? batteryInfo['furazolidones'] ?? '',
      },
      'weeding': locationCache ?? <String, dynamic>{},
      'cornels': <String, dynamic>{
        'cabins': identifiers.idfv,
        'typescripts': identifiers.idfv,
        'overtired': identifiers.idfa,
        'rased': DateTime.now().millisecondsSinceEpoch,
        'champaca': elapsed,
        'cauline': await native.getProxyEnabled(),
        'hygrometers': await native.getVpnEnabled(),
        'nonrailroad': await native.getRooted(),
        'endogamies': await native.getIsEmulator(),
        'uncinematic': await native.getDeviceLanguage(),
        'nimbus': await native.getCarrierName(),
        'nonhospital': await native.getNetworkType(),
        'saltchucks': const <Map<String, dynamic>>[],
        'swinish': await native.getTimeZoneId(),
        'treasurers': uptime,
      },
      'cattaloes': <String, dynamic>{
        'doohickey': 'Apple',
        'toyshop': await native.getCpuCores(),
        'calibrators': _screenHeight(),
        'copurifies': await native.getDeviceName(),
        'triglyphic': _screenWidth(),
        'madded': iosInfo?.modelName ?? androidInfo?.model ?? '',
        'smashingly':
            iosInfo?.systemVersion ?? androidInfo?.version.release ?? '',
        'certify': packageInfo.version,
        'porcelainlike': await native.getScreenInches(),
      },
      'polygraphist': <String, dynamic>{
        'waggeries': _text(wifiInfo['ip']),
        'accolade': <Map<String, dynamic>>[_wifiItem(wifiInfo)],
        'archetype': _wifiItem(wifiInfo),
        'intimidation': _int(wifiInfo['wifiCount']),
      },
      'integrated': storageInfo,
    };

    return jsonEncode(payload);
  }

  Map<String, dynamic> _wifiItem(Map<String, dynamic> wifiInfo) {
    return <String, dynamic>{
      'misdescribing': _text(wifiInfo['ssid']),
      'foodie': _text(wifiInfo['bssid']),
    };
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_text(value)) ?? 0;
  }

  static int _screenWidth() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final view = views.isEmpty ? null : views.first;
    return view?.physicalSize.width.toInt() ?? 0;
  }

  static int _screenHeight() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final view = views.isEmpty ? null : views.first;
    return view?.physicalSize.height.toInt() ?? 0;
  }

  static Future<PackageInfo> _packageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } on MissingPluginException {
      return PackageInfo(
        appName: '',
        packageName: '',
        version: '',
        buildNumber: '',
      );
    }
  }
}
