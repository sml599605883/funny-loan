import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'core/permissions/app_permission_service.dart';
import 'modules/main_tab/controllers/main_tab_controller.dart';
import 'core/widgets/keyboard_dismiss_on_tap.dart';
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
  bool _requestedNotificationPermission = false;
  bool _requestedTrackingPermission = false;
  bool _isPumpingStartupPermissions = false;
  bool _isRequestingForegroundPermission = false;
  bool _ignoreNextResumeHomeRefresh = false;
  Timer? _networkPermissionRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _pumpStartupPermissions();
    });
  }

  @override
  void dispose() {
    _networkPermissionRetryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        _isRequestingForegroundPermission) {
      _ignoreNextResumeHomeRefresh = true;
    }
    if (state == AppLifecycleState.resumed) {
      if (_ignoreNextResumeHomeRefresh) {
        _ignoreNextResumeHomeRefresh = false;
      } else if (Get.isRegistered<MainTabController>()) {
        Get.find<MainTabController>().onAppResumed();
      }
      unawaited(_pumpStartupPermissions());
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

  Future<void> _pumpStartupPermissions() async {
    if (_isPumpingStartupPermissions) {
      return;
    }
    _isPumpingStartupPermissions = true;
    try {
      final hasNetwork = await _hasUsableNetwork();
      if (!hasNetwork) {
        _schedulePermissionRetry();
        return;
      }

      if (!_requestedNotificationPermission) {
        _requestedNotificationPermission = true;
        await _requestForegroundPermission(
          AppPermissionService.requestNotification,
        );
      }

      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (lifecycleState != AppLifecycleState.resumed) {
        return;
      }

      if (!_requestedTrackingPermission) {
        _requestedTrackingPermission = true;
        await _requestForegroundPermission(
          AppPermissionService.requestTracking,
        );
      }
    } finally {
      _isPumpingStartupPermissions = false;
    }
  }

  void _schedulePermissionRetry() {
    _networkPermissionRetryTimer?.cancel();
    _networkPermissionRetryTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      unawaited(_pumpStartupPermissions());
    });
  }

  Future<bool> _hasUsableNetwork() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<T> _requestForegroundPermission<T>(
    Future<T> Function() request,
  ) async {
    _isRequestingForegroundPermission = true;
    try {
      return await request();
    } finally {
      _isRequestingForegroundPermission = false;
    }
  }

  void _handleRoutingChanged(Routing? routing) {
    if (routing?.current != AppRoutes.home ||
        !Get.isRegistered<MainTabController>()) {
      return;
    }
    Get.find<MainTabController>().onHomeRouteVisible();
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
