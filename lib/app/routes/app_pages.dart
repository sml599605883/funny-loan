import 'package:get/get.dart';

import '../modules/certification_step/views/certification_step_page.dart';
import '../modules/certification_step/views/certification_face_page.dart';
import '../modules/certification_step/views/certification_upload_page.dart';
import '../modules/certification_step/views/certification_upload_success_page.dart';
import '../modules/detail/views/detail_page.dart';
import '../modules/login/controllers/login_controller.dart';
import '../modules/login/views/login_page.dart';
import '../modules/main_tab/views/main_tab_page.dart';
import '../modules/order_list/views/order_list_page.dart';
import '../modules/setting/views/setting_page.dart';
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
    GetPage(
      name: AppRoutes.setting,
      page: () => const SettingPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.orderList,
      page: () => const OrderListPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationStep,
      page: () => const CertificationStepPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationUpload,
      page: () => const CertificationUploadPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationFace,
      page: () => const CertificationFacePage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationUploadSuccess,
      page: () => const CertificationUploadSuccessPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
