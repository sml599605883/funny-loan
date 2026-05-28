import 'package:get/get.dart';

import '../modules/detail/views/detail_page.dart';
import '../modules/main_tab/views/main_tab_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.home, page: () => const MainTabPage()),
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
