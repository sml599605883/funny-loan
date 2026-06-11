import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/json/json.dart';
import '../core/permissions/app_permission_service.dart';
import '../core/storage/app_data_store.dart';
import '../network/api/api_service.dart';
import '../network/config/network_config.dart';
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

  static const targetTypeAppPage = 'appPage';
  static const targetTypeWebUrl = 'webUrl';
  static const targetTypeUnsupported = 'unsupported';
  static const targetTypeNone = 'none';

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
      await _dispatchRawTarget(
        rawTarget,
        isNative: response.data['outcrop'].intValue == 0,
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

  static Map<String, dynamic> resolveDecision(Json json) {
    final rawTarget = json['sidearms'].stringValue.trim();
    final isNative = json['outcrop'].intValue == 0;

    if (rawTarget.isEmpty) {
      return <String, dynamic>{
        'type': targetTypeNone,
        'rawTarget': '',
        'normalizedAppPage': '',
        'webUrl': null,
        'isNative': isNative,
      };
    }

    final appPage = NavigationTargetMapper.appPageFromTarget(rawTarget);
    if (appPage != null && appPage.isNotEmpty) {
      return <String, dynamic>{
        'type': targetTypeAppPage,
        'rawTarget': rawTarget,
        'normalizedAppPage': appPage,
        'webUrl': null,
        'isNative': isNative,
      };
    }

    final webUrl = _resolveWebUrl(rawTarget);
    if (webUrl != null) {
      return <String, dynamic>{
        'type': targetTypeWebUrl,
        'rawTarget': rawTarget,
        'normalizedAppPage': '',
        'webUrl': webUrl,
        'isNative': isNative,
      };
    }

    return <String, dynamic>{
      'type': targetTypeUnsupported,
      'rawTarget': rawTarget,
      'normalizedAppPage': '',
      'webUrl': null,
      'isNative': isNative,
    };
  }

  static Future<void> dispatchDecision(
    Map<String, dynamic> decision, {
    Object? detailArguments,
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    switch (decision['type']) {
      case targetTypeAppPage:
        final normalizedAppPage =
            decision['normalizedAppPage'] as String? ?? '';
        if (normalizedAppPage == NavigationTargetMapper.productDetail) {
          await _dispatchProductDetailDecision(
            decision,
            urlLauncher: urlLauncher,
          );
          return;
        }
        NavigationHelper.toAppPage(
          normalizedAppPage,
          arguments: detailArguments,
        );
        return;
      case targetTypeWebUrl:
        final uri = decision['webUrl'] as Uri?;
        if (uri == null) {
          return;
        }
        await (urlLauncher ?? _launchExternalUrl).call(uri);
        return;
      case targetTypeUnsupported:
      case targetTypeNone:
        return;
      default:
        return;
    }
  }

  static Future<void> _dispatchProductDetailDecision(
    Map<String, dynamic> decision, {
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final productId = _cohabiterFromTarget(
      decision['rawTarget'] as String? ?? '',
    );
    if (productId.isEmpty) {
      return;
    }

    final productDetail = await _fetchProductDetailByProductId(productId);
    await _handleProductDetailFlow(productDetail, urlLauncher: urlLauncher);
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
      final redirect = await _fetchOrderRedirectByOrderNo(orderNo);
      final rawTarget = (redirect['sidearms'] as String? ?? '').trim();
      if (rawTarget.isNotEmpty) {
        await _dispatchRawTarget(
          rawTarget,
          isNative: redirect['outcrop'] == 0 || redirect['outcrop'] == '0',
          detailArguments: productDetail,
          urlLauncher: urlLauncher,
        );
        return;
      }
      final message = (redirect['reallot'] as String? ?? '').trim();
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

  static Future<Map<String, dynamic>> _fetchOrderRedirectByOrderNo(
    String orderNo,
  ) async {
    final response = await _apiService.fetchOrderRedirect(<String, dynamic>{
      'orderNo': orderNo,
    });
    return response.data.mapValue;
  }

  static Future<void> _dispatchRawTarget(
    String rawTarget, {
    required bool isNative,
    Object? detailArguments,
    Future<bool> Function(Uri uri)? urlLauncher,
  }) {
    final decision = resolveDecision(
      Json(<String, dynamic>{
        'sidearms': rawTarget,
        'outcrop': isNative ? 0 : 1,
        'gewurztraminers': 0,
      }),
    );
    return dispatchDecision(
      decision,
      detailArguments: detailArguments,
      urlLauncher: urlLauncher,
    );
  }

  static String _cohabiterFromTarget(String rawTarget) {
    final uri = Uri.tryParse(rawTarget.trim());
    return uri?.queryParameters['cohabiter']?.trim() ?? '';
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

  static Future<bool> _launchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _tokenProvider() {
    return AppDataStore.getPersistentString(AppDataStore.persistedTokenKey) ??
        '';
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

class _LocationFlowResult {
  const _LocationFlowResult({required this.shouldContinue});

  final bool shouldContinue;
}
