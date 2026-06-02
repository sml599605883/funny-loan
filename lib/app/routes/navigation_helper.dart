import 'package:get/get.dart';

import '../modules/main_tab/controllers/main_tab_controller.dart';
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
}
