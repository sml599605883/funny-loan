import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'modules/main_tab/controllers/main_tab_controller.dart';
import 'core/widgets/keyboard_dismiss_on_tap.dart';
import 'report/report_manager.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_colors.dart';
import 'theme/screen_adapter.dart';

class FunnyLoanApp extends StatefulWidget {
  const FunnyLoanApp({super.key});

  @override
  State<FunnyLoanApp> createState() => _FunnyLoanAppState();
}

class _FunnyLoanAppState extends State<FunnyLoanApp>
    with WidgetsBindingObserver {
  bool _ignoreNextResumeHomeRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<ReportManager>()) {
        unawaited(Get.find<ReportManager>().onAppStarted());
      }
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<ReportManager>()) {
      unawaited(Get.find<ReportManager>().dispose());
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        _reportManager?.isRequestingForegroundPermission == true) {
      _ignoreNextResumeHomeRefresh = true;
    }
    if (state == AppLifecycleState.resumed) {
      final reportManager = _reportManager;
      if (reportManager != null) {
        unawaited(reportManager.onAppResumed());
      }
      if (_ignoreNextResumeHomeRefresh) {
        _ignoreNextResumeHomeRefresh = false;
      } else if (Get.isRegistered<MainTabController>()) {
        Get.find<MainTabController>().onAppResumed();
      }
    }
  }

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
      initialRoute: AppRoutes.home,
      routingCallback: _handleRoutingChanged,
      defaultTransition: Transition.rightToLeft,
      popGesture: false,
    );
  }

  void _handleRoutingChanged(Routing? routing) {
    if (routing?.current != AppRoutes.home ||
        !Get.isRegistered<MainTabController>()) {
      return;
    }
    Get.find<MainTabController>().onHomeRouteVisible();
  }

  ReportManager? get _reportManager =>
      Get.isRegistered<ReportManager>() ? Get.find<ReportManager>() : null;

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
