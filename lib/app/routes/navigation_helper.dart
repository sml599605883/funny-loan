import 'package:get/get.dart';

import '../modules/main_tab/controllers/main_tab_controller.dart';
import 'app_routes.dart';
import 'navigation_target_mapper.dart';

class NavigationHelper {
  NavigationHelper._();

  static void back<T extends Object?>({T? result}) {
    Get.back<T>(result: result);
  }

  static Future<T?>? toLogin<T extends Object?>() {
    return Get.toNamed<T>(AppRoutes.login);
  }

  static Future<T?>? offAllToHome<T extends Object?>() {
    return Get.offAllNamed<T>(AppRoutes.home);
  }

  static Future<T?>? offAllToAppHome<T extends Object?>() {
    if (Get.isRegistered<MainTabController>()) {
      Get.find<MainTabController>().backToHomeTab();
    }
    return Get.offAllNamed<T>(AppRoutes.home);
  }

  static Future<T?>? toDetail<T extends Object?>({Object? arguments}) {
    return Get.toNamed<T>(AppRoutes.detail, arguments: arguments);
  }

  static Future<T?>? toSetting<T extends Object?>() {
    return Get.toNamed<T>(AppRoutes.setting);
  }

  static Future<T?>? toOrderList<T extends Object?>({
    int initialTab = 0,
  }) {
    return Get.toNamed<T>(
      AppRoutes.orderList,
      arguments: <String, dynamic>{'initialTab': initialTab},
    );
  }

  static Future<T?>? toCertificationStep<T extends Object?>({
    required String routeKey,
    Object? arguments,
  }) {
    return Get.toNamed<T>(
      AppRoutes.certificationStep,
      arguments: <String, dynamic>{
        'routeKey': routeKey,
        'payload': arguments,
      },
    );
  }

  static Future<T?>? toCertificationUpload<T extends Object?>({
    Object? arguments,
  }) {
    return Get.toNamed<T>(
      AppRoutes.certificationUpload,
      arguments: arguments,
    );
  }

  static Future<T?>? toCertificationUploadSuccess<T extends Object?>({
    Object? arguments,
  }) {
    return Get.toNamed<T>(
      AppRoutes.certificationUploadSuccess,
      arguments: arguments,
    );
  }

  static Future<T?>? toAppPage<T extends Object?>(
    String rawPage, {
    Object? arguments,
    Object? orderStatusCode,
  }) {
    switch (NavigationTargetMapper.normalizeAppPage(rawPage)) {
      case NavigationTargetMapper.main:
        return offAllToAppHome<T>();
      case NavigationTargetMapper.setting:
        return toSetting<T>();
      case NavigationTargetMapper.login:
        return toLogin<T>();
      case NavigationTargetMapper.order:
        return toOrderList<T>(
          initialTab: NavigationTargetMapper.orderTabIndexForCode(
            orderStatusCode,
          ),
        );
      case NavigationTargetMapper.productDetail:
        return toDetail<T>(arguments: arguments);
      default:
        if (NavigationTargetMapper.isCertificationStepRouteKey(rawPage)) {
          return toCertificationStep<T>(
            routeKey: NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ),
            arguments: arguments,
          );
        }
        return null;
    }
  }
}
