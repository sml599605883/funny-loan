import 'dart:async';

import 'package:get/get.dart';

import '../../../modules/home/controllers/home_controller.dart';
import '../../../network/api/api_service.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../routes/app_routes.dart';

typedef RecreditApiServiceProvider = ApiService Function();
typedef RecreditRouteProvider = String Function();
typedef RecreditHomeRefresher = Future<void> Function();
typedef RecreditAdmissionRunner = Future<void> Function(String productId);

class RecreditPollingCoordinator {
  RecreditPollingCoordinator({
    RecreditApiServiceProvider? apiServiceProvider,
    RecreditRouteProvider? currentRouteProvider,
    RecreditHomeRefresher? homeRefresher,
    RecreditAdmissionRunner? admissionRunner,
    this.interval = const Duration(seconds: 10),
  }) : _apiServiceProvider =
           apiServiceProvider ?? (() => Get.find<ApiService>()),
       _currentRouteProvider = currentRouteProvider ?? (() => Get.currentRoute),
       _homeRefresher = homeRefresher ?? _refreshHome,
       _admissionRunner = admissionRunner ?? _runAdmissionAfterRecredit;

  final RecreditApiServiceProvider _apiServiceProvider;
  final RecreditRouteProvider _currentRouteProvider;
  final RecreditHomeRefresher _homeRefresher;
  final RecreditAdmissionRunner _admissionRunner;
  final Duration interval;

  Timer? _timer;
  String _productId = '';
  bool _isRequesting = false;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  void start({required String productId}) {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    _productId = normalizedProductId;
    _isRunning = true;
    _timer?.cancel();
    _scheduleNextTick(Duration.zero);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isRequesting = false;
  }

  void _scheduleNextTick(Duration delay) {
    if (!_isRunning) {
      return;
    }
    _timer = Timer(delay, _requestRefreshCredit);
  }

  Future<void> _requestRefreshCredit() async {
    if (!_isRunning || _isRequesting) {
      return;
    }
    _isRequesting = true;
    try {
      final response = await _apiServiceProvider().refreshCredit(
        <String, dynamic>{'forevers': _productId},
      );
      final result = response.data['gewurztraminers'].intValue;
      if (result == 1) {
        await _handleCompleted();
        return;
      }
      if (result == 2) {
        _isRequesting = false;
        _scheduleNextTick(interval);
        return;
      }
    } catch (_) {
      _isRequesting = false;
      _scheduleNextTick(interval);
      return;
    }
    _isRequesting = false;
    _scheduleNextTick(interval);
  }

  Future<void> _handleCompleted() async {
    final completedRoute = _currentRouteProvider();
    stop();
    if (completedRoute == AppRoutes.home) {
      await _homeRefresher();
      return;
    }
    if (completedRoute == AppRoutes.recredit) {
      await _admissionRunner(_productId);
    }
  }

  static Future<void> _refreshHome() async {
    if (!Get.isRegistered<HomeController>()) {
      return;
    }
    await Get.find<HomeController>().fetchHomeData();
  }

  static Future<void> _runAdmissionAfterRecredit(String productId) async {
    await ApiNavigationHelper.applyProductAndNavigate(productId);
  }
}

class RecreditPollingBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<RecreditPollingCoordinator>()) {
      return;
    }
    Get.put<RecreditPollingCoordinator>(
      RecreditPollingCoordinator(),
      permanent: true,
    );
  }
}
