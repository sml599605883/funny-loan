import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/json/json.dart';
import '../core/permissions/app_permission_service.dart';
import '../core/storage/app_data_store.dart';
import '../network/api/api_service.dart';
import '../network/config/network_config.dart';
import '../report/report_manager.dart';
import 'navigation_helper.dart';
import 'navigation_target_mapper.dart';

enum LocationPermissionDialogAction { cancel, settings }

typedef LoginNavigator = Future<void> Function();
typedef TokenProvider = String Function();
typedef LocationServiceEnabledProvider = Future<bool> Function();
typedef RequestLocationPermission = Future<PermissionStatus> Function();
typedef LocationPermissionDialog =
    Future<LocationPermissionDialogAction> Function();
typedef OpenAppSettingsPage = Future<bool> Function();
typedef ApplyProductRequest =
    Future<Map<String, dynamic>> Function(String cohabiter, String? allantoins);

class ApiNavigationHelper {
  ApiNavigationHelper._();

  static Future<void> applyProductAndNavigate(
    String cohabiter, {
    String? allantoins,
    Object? detailArguments,
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final token = _tokenProvider().trim();
    if (token.isEmpty) {
      EasyLoading.dismiss();
      await NavigationHelper.toLogin();
      return;
    }

    await _reportLocationAfterLoginCheck();

    final locationFlowResult = await _ensureLocationReady(
      locationServiceEnabledProvider: _locationServiceEnabledProvider,
      requestLocationPermission: AppPermissionService.requestLocationWhenInUse,
      locationServiceDialog: _showLocationServiceDialog,
      locationPermissionDialog: _showLocationPermissionDialog,
      openAppSettingsPage: AppPermissionService.openAppSettingsPage,
    );
    if (!locationFlowResult.shouldContinue) {
      return;
    }

    final response = await _apiService.applyProduct(
      _buildApplyProductBody(cohabiter: cohabiter, allantoins: allantoins),
    );
    final rawTarget = response.data['sidearms'].stringValue.trim();
    if (rawTarget.isNotEmpty) {
      await navigateRawTarget(
        rawTarget,
        detailArguments: detailArguments,
        urlLauncher: urlLauncher,
      );
      return;
    }

    if (response.data['gewurztraminers'].intValue == 200) {
      await fetchProductDetailByProductId(cohabiter);
      return;
    }

    final message = response.data['reallot'].stringValue.trim();
    if (message.isNotEmpty) {
      EasyLoading.showToast(message);
    }
  }

  static Future<void> navigateRawTarget(
    String rawTarget, {
    Object? detailArguments,
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final target = _parseRawTarget(rawTarget);
    if (target == null) {
      return;
    }
    switch (target.type) {
      case _NavigationTargetType.appPage:
        if (target.appPage == NavigationTargetMapper.productDetail) {
          final productId = _cohabiterFromTarget(target.rawTarget);
          if (productId.isEmpty) {
            return;
          }
          final productDetail = await _fetchProductDetailByProductId(productId);
          await _handleProductDetailFlow(
            productDetail,
            urlLauncher: urlLauncher,
          );
          return;
        }
        NavigationHelper.toAppPage(target.appPage!, arguments: detailArguments);
        return;
      case _NavigationTargetType.webUrl:
        if (urlLauncher != null) {
          await urlLauncher.call(target.webUri!);
          return;
        }
        NavigationHelper.toWebView(target.webUri!.toString());
        return;
    }
  }

  static Future<Map<String, dynamic>> fetchProductDetail(
    Map<String, dynamic> body,
  ) async {
    final response = await _apiService.fetchProductDetail(body);
    return parseProductDetail(response.data);
  }

  static Map<String, dynamic> parseProductDetail(Json json) {
    final authItems = json['oocytes'].listValue
        .map((item) => _parseAuthItem(Json(item)))
        .toList();
    final nextStep = json['tetragrammaton'];
    final scabiosa = _parseScabiosa(json['scabiosa']);
    AppDataStore.setCache(AppDataStore.productDetailScabiosaCacheKey, scabiosa);
    return <String, dynamic>{
      'productId': json['accretes']['isolines'].stringValue,
      'productName': json['accretes']['disprovable'].stringValue,
      'orderNo': json['accretes']['rejectee'].stringValue,
      'amount': json['accretes']['unfindable'].stringValue,
      'term': json['accretes']['temerariousness'].stringValue,
      'termType': json['accretes']['lixiviates'].stringValue,
      'resultCode': json['gewurztraminers'].intValue,
      'message': json['reallot'].stringValue,
      'hasNextStep': nextStep.mapValue.isNotEmpty,
      'nextStepCode': nextStep['sidearms'].stringValue,
      'nextStepTitle': nextStep['hazinesses'].stringValue,
      'nextStepTarget': nextStep['rutherfordiums'].stringValue,
      'nextStepIsNative': nextStep['outcrop'].intValue == 0,
      'scabiosa': scabiosa,
      'authItems': authItems,
    };
  }

  static Map<String, String> getCachedProductDetailScabiosa() {
    final cached = AppDataStore.getCache<Map<String, String>>(
      AppDataStore.productDetailScabiosaCacheKey,
    );
    return cached ?? const <String, String>{};
  }

  static Future<void> _handleProductDetailFlow(
    Map<String, dynamic> productDetail, {
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final nextStepRoute = (productDetail['nextStepTarget'] as String? ?? '')
        .trim();
    if (nextStepRoute.isNotEmpty) {
      NavigationHelper.toAppPage(nextStepRoute, arguments: productDetail);
      return;
    }

    if ((productDetail['resultCode'] as int? ?? 0) == 200) {
      final orderNo = (productDetail['orderNo'] as String? ?? '').trim();
      if (orderNo.isEmpty) {
        return;
      }
      final redirect = await _fetchOrderRedirectByOrderNo(productDetail);
      _reportRiskScene(
        sceneType: ReportRiskScene.orderConfirm,
        productId: (productDetail['productId'] as String? ?? '').trim(),
        orderNo: orderNo,
        startTime: _currentSecondsTimestamp(),
      );
      final nestedTarget = redirect['rekeys']['sidearms'].stringValue.trim();
      final rawTarget = nestedTarget.isNotEmpty
          ? nestedTarget
          : redirect['sidearms'].stringValue.trim();
      if (rawTarget.isNotEmpty) {
        await navigateRawTarget(
          rawTarget,
          detailArguments: productDetail,
          urlLauncher: urlLauncher,
        );
        return;
      }
      final message = redirect['gluteal'].stringValue.trim();
      if (message.isNotEmpty) {
        EasyLoading.showToast(message);
      }
      return;
    }

    final message = (productDetail['message'] as String? ?? '').trim();
    if (message.isNotEmpty) {
      EasyLoading.showToast(message);
    }
  }

  static Map<String, dynamic> _parseAuthItem(Json json) {
    return <String, dynamic>{
      'title': json['hazinesses'].stringValue,
      'routeKey': NavigationTargetMapper.normalizeProductDetailAuthItemCode(
        json['rutherfordiums'].stringValue,
      ),
      'target': json['sidearms'].stringValue,
      'isNative': json['outcrop'].intValue == 0,
      'isFinished': json['fleshed'].intValue == 1,
    };
  }

  static Map<String, String> _parseScabiosa(Json json) {
    return <String, String>{
      'beveling': json['beveling'].stringValue,
      'vicomtes': json['vicomtes'].stringValue,
      'extricating': json['extricating'].stringValue,
      'verves': json['verves'].stringValue,
      'presumably': json['presumably'].stringValue,
      'wolframite': json['wolframite'].stringValue,
      'cytokinetic': json['cytokinetic'].stringValue,
      'omitted': json['omitted'].stringValue,
    };
  }

  static Map<String, dynamic> _buildApplyProductBody({
    required String cohabiter,
    String? allantoins,
  }) {
    final body = <String, dynamic>{'cohabiter': cohabiter};
    final remindSource = allantoins?.trim() ?? '';
    if (remindSource.isNotEmpty) {
      body['allantoins'] = remindSource;
    }
    return body;
  }

  static Future<void> fetchProductDetailByProductId(
    String cohabiter, {
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final productDetail = await _fetchProductDetailByProductId(cohabiter);
    await _handleProductDetailFlow(productDetail, urlLauncher: urlLauncher);
  }

  static Future<Map<String, dynamic>> _fetchProductDetailByProductId(
    String cohabiter,
  ) {
    return fetchProductDetail(<String, dynamic>{'cohabiter': cohabiter});
  }

  static Future<Json> _fetchOrderRedirectByOrderNo(
    Map<String, dynamic> productDetail,
  ) async {
    final response = await _apiService.fetchOrderRedirect(<String, dynamic>{
      'nosh': (productDetail['orderNo'] as String? ?? '').trim(),
      'unfindable': (productDetail['amount'] as String? ?? '').trim(),
      'temerariousness': (productDetail['term'] as String? ?? '').trim(),
      'lixiviates': (productDetail['termType'] as String? ?? '').trim(),
    });
    return response.data;
  }

  static String _cohabiterFromTarget(String rawTarget) {
    final uri = Uri.tryParse(rawTarget.trim());
    return uri?.queryParameters['cohabiter']?.trim() ?? '';
  }

  static _NavigationTarget? _parseRawTarget(String rawTarget) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return null;
    }

    final appPage = NavigationTargetMapper.appPageFromTarget(target);
    if (appPage != null && appPage.isNotEmpty) {
      return _NavigationTarget.appPage(target, appPage);
    }

    final webUri = _resolveWebUrl(target);
    if (webUri != null) {
      return _NavigationTarget.webUrl(target, webUri);
    }

    return null;
  }

  static Uri? _resolveWebUrl(String rawTarget) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return null;
    }
    final absolute = Uri.tryParse(target);
    if (absolute != null &&
        (absolute.scheme == 'http' || absolute.scheme == 'https')) {
      return absolute;
    }
    if (target.startsWith('/#/')) {
      final baseUrl = _networkState.webBaseUrl.trim();
      if (baseUrl.isEmpty) {
        return null;
      }
      return Uri.tryParse('$baseUrl$target');
    }
    return null;
  }

  static String _tokenProvider() {
    return AppDataStore.getPersistentString(AppDataStore.persistedTokenKey) ??
        '';
  }

  static Future<void> _reportLocationAfterLoginCheck() async {
    if (!Get.isRegistered<ReportManager>()) {
      return;
    }
    try {
      await Get.find<ReportManager>().reportLocationFromNative();
    } catch (_) {
      return;
    }
  }

  static void _reportRiskScene({
    required String sceneType,
    required String productId,
    required String orderNo,
    required String startTime,
  }) {
    if (!Get.isRegistered<ReportManager>()) {
      return;
    }
    unawaited(
      Get.find<ReportManager>().reportRiskScene(
        sceneType: sceneType,
        productId: productId,
        orderNo: orderNo,
        startTime: startTime,
      ),
    );
  }

  static String _currentSecondsTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }

  static Future<bool> _locationServiceEnabledProvider() async {
    return await Permission.locationWhenInUse.serviceStatus ==
        ServiceStatus.enabled;
  }

  static Future<_LocationFlowResult> _ensureLocationReady({
    required LocationServiceEnabledProvider locationServiceEnabledProvider,
    required RequestLocationPermission requestLocationPermission,
    required LocationPermissionDialog locationServiceDialog,
    required LocationPermissionDialog locationPermissionDialog,
    required OpenAppSettingsPage openAppSettingsPage,
  }) async {
    final serviceEnabled = await locationServiceEnabledProvider();
    if (!serviceEnabled) {
      final action = await locationServiceDialog();
      if (action == LocationPermissionDialogAction.settings) {
        await openAppSettingsPage();
        return const _LocationFlowResult(shouldContinue: false);
      }
      return const _LocationFlowResult(shouldContinue: true);
    }

    final permissionStatus = await requestLocationPermission();
    if (permissionStatus.isGranted) {
      return const _LocationFlowResult(shouldContinue: true);
    }

    final action = await locationPermissionDialog();
    if (action == LocationPermissionDialogAction.settings) {
      await openAppSettingsPage();
      return const _LocationFlowResult(shouldContinue: false);
    }
    return const _LocationFlowResult(shouldContinue: true);
  }

  static Future<LocationPermissionDialogAction>
  _showLocationServiceDialog() async {
    return _showLocationDialog(
      title: 'Location service required',
      message: 'Please enable device location service to continue.',
    );
  }

  static Future<LocationPermissionDialogAction>
  _showLocationPermissionDialog() async {
    return _showLocationDialog(
      title: 'Location permission required',
      message: 'Please enable app location permission to continue.',
    );
  }

  static Future<LocationPermissionDialogAction> _showLocationDialog({
    required String title,
    required String message,
  }) async {
    final result = await Get.dialog<LocationPermissionDialogAction>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Get.back(result: LocationPermissionDialogAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Get.back(result: LocationPermissionDialogAction.settings),
            child: const Text('Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? LocationPermissionDialogAction.cancel;
  }

  static ApiService get _apiService => Get.find<ApiService>();

  static MutableNetworkState get _networkState =>
      Get.find<MutableNetworkState>();
}

enum _NavigationTargetType { appPage, webUrl }

class _NavigationTarget {
  const _NavigationTarget._({
    required this.type,
    required this.rawTarget,
    this.appPage,
    this.webUri,
  });

  const _NavigationTarget.appPage(String rawTarget, String appPage)
    : this._(
        type: _NavigationTargetType.appPage,
        rawTarget: rawTarget,
        appPage: appPage,
      );

  const _NavigationTarget.webUrl(String rawTarget, Uri webUri)
    : this._(
        type: _NavigationTargetType.webUrl,
        rawTarget: rawTarget,
        webUri: webUri,
      );

  final _NavigationTargetType type;
  final String rawTarget;
  final String? appPage;
  final Uri? webUri;
}

class _LocationFlowResult {
  const _LocationFlowResult({required this.shouldContinue});

  final bool shouldContinue;
}
