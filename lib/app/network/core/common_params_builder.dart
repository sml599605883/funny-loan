import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CommonParamsBuilder {
  static String? _sessionId;

  static Future<Map<String, dynamic>> build() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final iosDeviceInfo = await deviceInfo.iosInfo;
    final deviceId = await _deviceId(deviceInfo);

    _sessionId ??= '';

    return <String, dynamic>{
      'tonometry': packageInfo.version,
      'lobate': iosDeviceInfo.modelName,
      'clepes': deviceId,
      'sextet': iosDeviceInfo.systemVersion,
      'manioc': _sessionId,
      'compliant': deviceId,
    };
  }

  static Future<String> _deviceId(DeviceInfoPlugin deviceInfo) async {
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? Platform.localHostname;
    }
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    return Platform.localHostname;
  }
}
