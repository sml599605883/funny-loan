import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'core/widgets/keyboard_dismiss_on_tap.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_colors.dart';
import 'theme/screen_adapter.dart';

class FunnyLoanApp extends StatelessWidget {
  const FunnyLoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    _configureEasyLoading();
    final easyLoadingBuilder = EasyLoading.init();
    return GetMaterialApp(
      title: 'Funny Loan',
      builder: (context, child) {
        ScreenAdapter.init(context);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.defaultBackgroundGradient,
            ),
          ),
          child: KeyboardDismissOnTap(
            child: easyLoadingBuilder(
              context,
              child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        canvasColor: Colors.transparent,
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
      ),
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      initialRoute: AppRoutes.login,
      defaultTransition: Transition.rightToLeft,
      popGesture: false,
    );
  }

  void _configureEasyLoading() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..maskType = EasyLoadingMaskType.black
      ..backgroundColor = const Color(0xCC1F2430)
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..maskColor = const Color(0x33000000)
      ..radius = 12
      ..dismissOnTap = false
      ..userInteractions = false;
  }
}
