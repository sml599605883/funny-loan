import 'package:get/get.dart';

import 'app_routes.dart';

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

  static Future<T?>? toDetail<T extends Object?>({Object? arguments}) {
    return Get.toNamed<T>(AppRoutes.detail, arguments: arguments);
  }
}
