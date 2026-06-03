import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/json/json.dart';
import '../core/storage/app_data_store.dart';
import '../network/api/api_service.dart';
import '../network/config/network_config.dart';
import 'navigation_helper.dart';
import 'navigation_target_mapper.dart';

class ApiNavigationHelper {
  ApiNavigationHelper._();

  static const targetTypeAppPage = 'appPage';
  static const targetTypeWebUrl = 'webUrl';
  static const targetTypeUnsupported = 'unsupported';
  static const targetTypeNone = 'none';

  static Future<Map<String, dynamic>> applyProductAndNavigate(
    String cohabiter, {
    String? allantoins,
    Object? detailArguments,
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final response = await _apiService.applyProduct(
      _buildApplyProductBody(cohabiter: cohabiter, allantoins: allantoins),
    );
    final decision = resolveDecision(response.data);
    return dispatchDecision(
      decision,
      detailArguments: detailArguments,
      urlLauncher: urlLauncher,
    );
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
    final resultCode = json['gewurztraminers'].intValue;
    final isNative = json['outcrop'].intValue == 0;

    if (rawTarget.isEmpty) {
      return <String, dynamic>{
        'type': targetTypeNone,
        'resultCode': resultCode,
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
        'resultCode': resultCode,
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
        'resultCode': resultCode,
        'rawTarget': rawTarget,
        'normalizedAppPage': '',
        'webUrl': webUrl,
        'isNative': isNative,
      };
    }

    return <String, dynamic>{
      'type': targetTypeUnsupported,
      'resultCode': resultCode,
      'rawTarget': rawTarget,
      'normalizedAppPage': '',
      'webUrl': null,
      'isNative': isNative,
    };
  }

  static Future<Map<String, dynamic>> dispatchDecision(
    Map<String, dynamic> decision, {
    Object? detailArguments,
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    switch (decision['type']) {
      case targetTypeAppPage:
        final normalizedAppPage =
            decision['normalizedAppPage'] as String? ?? '';
        if (normalizedAppPage == NavigationTargetMapper.productDetail) {
          final detailNavigation = await _dispatchProductDetailDecision(
            decision,
            urlLauncher: urlLauncher,
          );
          return <String, dynamic>{
            'handled': detailNavigation['handled'] == true,
            'decision': decision,
            'productDetail': detailNavigation['productDetail'],
            'nextStep': detailNavigation['nextStep'],
          };
        }
        final handled =
            NavigationHelper.toAppPage(
              normalizedAppPage,
              arguments: detailArguments,
            ) !=
            null;
        return <String, dynamic>{'handled': handled, 'decision': decision};
      case targetTypeWebUrl:
        final uri = decision['webUrl'] as Uri?;
        if (uri == null) {
          return <String, dynamic>{'handled': false, 'decision': decision};
        }
        final handled = await (urlLauncher ?? _launchExternalUrl).call(uri);
        return <String, dynamic>{'handled': handled, 'decision': decision};
      case targetTypeUnsupported:
      case targetTypeNone:
        return <String, dynamic>{'handled': false, 'decision': decision};
      default:
        return <String, dynamic>{'handled': false, 'decision': decision};
    }
  }

  static Future<Map<String, dynamic>> _dispatchProductDetailDecision(
    Map<String, dynamic> decision, {
    Future<bool> Function(Uri uri)? urlLauncher,
  }
  ) async {
    final productId = _cohabiterFromTarget(
      decision['rawTarget'] as String? ?? '',
    );
    if (productId.isEmpty) {
      return <String, dynamic>{
        'handled': false,
        'productDetail': null,
        'nextStep': null,
      };
    }

    final productDetail = await fetchProductDetailByProductId(productId);
    final nextStep = await _dispatchProductDetailNextStep(
      productDetail,
      urlLauncher: urlLauncher,
    );
    return <String, dynamic>{
      'handled': nextStep['handled'] == true,
      'productDetail': productDetail,
      'nextStep': nextStep,
    };
  }

  static Future<Map<String, dynamic>> _dispatchProductDetailNextStep(
    Map<String, dynamic> productDetail, {
    Future<bool> Function(Uri uri)? urlLauncher,
  }) async {
    final nextStepTarget = (productDetail['nextStepTarget'] as String? ?? '')
        .trim();
    final nextStepCode = (productDetail['nextStepCode'] as String? ?? '').trim();
    final nextStepIsNative = productDetail['nextStepIsNative'] == true;

    if (nextStepTarget.isNotEmpty) {
      if (nextStepIsNative) {
        final directHandled =
            NavigationHelper.toAppPage(
              nextStepTarget,
              arguments: productDetail,
            ) !=
            null;
        if (directHandled) {
          return <String, dynamic>{
            'handled': true,
            'decision': null,
            'routeKey': nextStepTarget,
          };
        }

        final fallbackHandled =
            NavigationHelper.toCertificationStep(
              routeKey: nextStepTarget,
              arguments: productDetail,
            ) !=
            null;
        if (fallbackHandled) {
          return <String, dynamic>{
            'handled': true,
            'decision': null,
            'routeKey': nextStepTarget,
          };
        }
      }

      final decision = resolveDecision(
        Json(<String, dynamic>{
          'sidearms': nextStepTarget,
          'outcrop': nextStepIsNative ? 0 : 1,
          'gewurztraminers': 0,
        }),
      );
      final result = await dispatchDecision(
        decision,
        detailArguments: productDetail,
        urlLauncher: urlLauncher,
      );
      if (result['handled'] == true) {
        return <String, dynamic>{
          'handled': true,
          'decision': decision,
          'routeKey': nextStepCode,
        };
      }
    }

    if (nextStepCode.isNotEmpty) {
      final handled = NavigationHelper.toAppPage(
            NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              nextStepCode,
            ),
            arguments: productDetail,
          ) !=
          null;
      return <String, dynamic>{
        'handled': handled,
        'decision': null,
        'routeKey': nextStepCode,
      };
    }

    return <String, dynamic>{
      'handled': false,
      'decision': null,
      'routeKey': '',
    };
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

  static Future<Map<String, dynamic>> fetchProductDetailByProductId(
    String cohabiter,
  ) {
    return fetchProductDetail(<String, dynamic>{'cohabiter': cohabiter});
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

  static ApiService get _apiService => Get.find<ApiService>();

  static MutableNetworkState get _networkState =>
      Get.find<MutableNetworkState>();
}
