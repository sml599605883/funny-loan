import 'package:get/get.dart';

import '../modules/card_list/views/card_list_page.dart';
import '../modules/certification_step/views/certification_step_page.dart';
import '../modules/certification_step/views/certification_bind_card_page.dart';
import '../modules/certification_step/views/certification_face_page.dart';
import '../modules/certification_step/views/certification_contact_info_page.dart';
import '../modules/certification_step/views/certification_personal_info_page.dart';
import '../modules/certification_step/views/certification_upload_page.dart';
import '../modules/certification_step/views/certification_upload_success_page.dart';
import '../modules/certification_step/views/certification_work_info_page.dart';
import '../modules/detail/views/detail_page.dart';
import '../modules/login/controllers/login_controller.dart';
import '../modules/login/views/login_page.dart';
import '../modules/main_tab/views/main_tab_page.dart';
import '../modules/order_list/views/order_list_page.dart';
import '../modules/setting/views/setting_page.dart';
import '../modules/webview/views/webview_page.dart';
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
    GetPage(
      name: AppRoutes.certificationPersonalInfo,
      page: () => const CertificationPersonalInfoPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationWorkInfo,
      page: () => const CertificationWorkInfoPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationContactInfo,
      page: () => const CertificationContactInfoPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.certificationBindCard,
      page: () => const CertificationBindCardPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.cardList,
      page: () => const CardListPage(),
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
    GetPage(
      name: AppRoutes.webview,
      page: () {
        final arguments = Get.arguments;
        final mapped = arguments is Map
            ? Map<String, dynamic>.from(arguments)
            : const <String, dynamic>{};
        return FunnyLoanWebViewPage(
          initialUrl: (mapped['url'] as String? ?? '').trim(),
          initialTitle: (mapped['title'] as String? ?? '').trim(),
        );
      },
      transition: Transition.rightToLeft,
      popGesture: false,
    ),
  ];
}
