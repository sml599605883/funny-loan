import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  AppPermissionService._();

  static Future<PermissionStatus> requestLocationWhenInUse() {
    return Permission.locationWhenInUse.request();
  }

  static Future<PermissionStatus> requestCamera() {
    return Permission.camera.request();
  }

  static Future<PermissionStatus> requestNotification() {
    return Permission.notification.request();
  }

  static Future<PermissionStatus> requestTracking() async {
    if (!Platform.isIOS) {
      return PermissionStatus.granted;
    }
    return Permission.appTrackingTransparency.request();
  }

  static Future<Map<AppPermissionType, PermissionStatus>>
  requestCorePermissions() async {
    final results = <AppPermissionType, PermissionStatus>{};

    results[AppPermissionType.location] =
        await Permission.locationWhenInUse.request();
    results[AppPermissionType.camera] = await Permission.camera.request();
    results[AppPermissionType.notification] =
        await Permission.notification.request();

    if (Platform.isIOS) {
      results[AppPermissionType.tracking] =
          await Permission.appTrackingTransparency.request();
    } else {
      results[AppPermissionType.tracking] = PermissionStatus.granted;
    }

    return results;
  }

  static Future<Map<AppPermissionType, PermissionStatus>>
  currentCorePermissionStatuses() async {
    final results = <AppPermissionType, PermissionStatus>{};

    results[AppPermissionType.location] =
        await Permission.locationWhenInUse.status;
    results[AppPermissionType.camera] = await Permission.camera.status;
    results[AppPermissionType.notification] =
        await Permission.notification.status;
    results[AppPermissionType.tracking] = Platform.isIOS
        ? await Permission.appTrackingTransparency.status
        : PermissionStatus.granted;

    return results;
  }

  static Future<bool> openAppSettingsPage() {
    return openAppSettings();
  }
}

enum AppPermissionType {
  location,
  camera,
  notification,
  tracking,
}
