import 'package:get/get.dart';

import '../modules/detail/views/detail_page.dart';
import '../modules/login/controllers/login_controller.dart';
import '../modules/login/views/login_page.dart';
import '../modules/main_tab/views/main_tab_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
    ),
    GetPage(name: AppRoutes.home, page: () => const MainTabPage()),
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
