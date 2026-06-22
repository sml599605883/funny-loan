import 'package:get/get.dart';

import '../modules/main_tab/controllers/main_tab_controller.dart';
import 'app_routes.dart';
import 'navigation_target_mapper.dart';

class NavigationHelper {
  NavigationHelper._();

  static const Set<String> _certificationFlowPrunedRouteNames = <String>{
    AppRoutes.certificationStep,
    AppRoutes.certificationUpload,
    AppRoutes.certificationUploadSuccess,
    AppRoutes.certificationFace,
    AppRoutes.certificationPersonalInfo,
    AppRoutes.certificationWorkInfo,
    AppRoutes.certificationContactInfo,
    AppRoutes.certificationBindCard,
    AppRoutes.cardList,
    AppRoutes.recredit,
    AppRoutes.webview,
  };

  static void back<T extends Object?>({T? result}) {
    Get.back<T>(result: result);
  }

  static Future<T?>? toLogin<T extends Object?>() {
    return Get.toNamed<T>(AppRoutes.login);
  }

  static Future<T?>? offAllToHome<T extends Object?>() {
    return Get.offAllNamed<T>(AppRoutes.home);
  }

  static Future<T?>? offAllToAppHome<T extends Object?>() {
    if (Get.isRegistered<MainTabController>()) {
      Get.find<MainTabController>().backToHomeTab();
    }
    return Get.offAllNamed<T>(AppRoutes.home);
  }

  static Future<T?>? toDetail<T extends Object?>({Object? arguments}) {
    return Get.toNamed<T>(AppRoutes.detail, arguments: arguments);
  }

  static Future<T?>? toSetting<T extends Object?>() {
    return Get.toNamed<T>(AppRoutes.setting);
  }

  static Future<T?>? toWebView<T extends Object?>(String url) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.webview,
      arguments: <String, dynamic>{'url': url.trim()},
    );
  }

  static Future<T?>? toOrderList<T extends Object?>({int initialTab = 0}) {
    return Get.toNamed<T>(
      AppRoutes.orderList,
      arguments: <String, dynamic>{'initialTab': initialTab},
    );
  }

  static Future<T?>? toMineOrderList<T extends Object?>({int initialTab = 0}) {
    return Get.toNamed<T>(
      AppRoutes.mineOrderList,
      arguments: <String, dynamic>{'initialTab': initialTab},
    );
  }

  static Future<T?>? toCertificationStep<T extends Object?>({
    required String routeKey,
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationStep,
      arguments: <String, dynamic>{'routeKey': routeKey, 'payload': arguments},
    );
  }

  static Future<T?>? toCertificationUpload<T extends Object?>({
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationUpload,
      arguments: arguments,
    );
  }

  static Future<T?>? toCertificationFace<T extends Object?>({
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationFace,
      arguments: arguments,
    );
  }

  static Future<T?>? toCertificationUploadSuccess<T extends Object?>({
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationUploadSuccess,
      arguments: arguments,
    );
  }

  static Future<T?>? toCertificationPersonalInfo<T extends Object?>({
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationPersonalInfo,
      arguments: _normalizeCertificationPayloadArguments(arguments),
    );
  }

  static Future<T?>? toCertificationWorkInfo<T extends Object?>({
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationWorkInfo,
      arguments: _normalizeCertificationPayloadArguments(arguments),
    );
  }

  static Future<T?>? toCertificationContactInfo<T extends Object?>({
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationContactInfo,
      arguments: _normalizeCertificationPayloadArguments(arguments),
    );
  }

  static Future<T?>? toCertificationBindCard<T extends Object?>({
    required String routeKey,
    Object? arguments,
  }) {
    return _toNamedAfterPruningCertificationFlow<T>(
      AppRoutes.certificationBindCard,
      arguments: <String, dynamic>{
        'routeKey': routeKey,
        ..._normalizeCertificationPayloadArguments(arguments),
      },
    );
  }

  static Future<T?>? toCardList<T extends Object?>({Object? arguments}) {
    return Get.toNamed<T>(AppRoutes.cardList, arguments: arguments);
  }

  static Future<T?>? toAppPage<T extends Object?>(
    String rawPage, {
    Object? arguments,
    Object? orderStatusCode,
  }) {
    switch (NavigationTargetMapper.normalizeAppPage(rawPage)) {
      case NavigationTargetMapper.main:
        return offAllToAppHome<T>();
      case NavigationTargetMapper.setting:
        return toSetting<T>();
      case NavigationTargetMapper.login:
        return toLogin<T>();
      case NavigationTargetMapper.order:
        return toOrderList<T>(
          initialTab: NavigationTargetMapper.orderTabIndexForCode(
            orderStatusCode,
          ),
        );
      case NavigationTargetMapper.productDetail:
        return toDetail<T>(arguments: arguments);
      case NavigationTargetMapper.recredit:
        return Get.toNamed<T>(AppRoutes.recredit, arguments: arguments);
      default:
        if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ) ==
            'bank') {
          return toCertificationBindCard<T>(
            routeKey: NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ),
            arguments: arguments,
          );
        }
        if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ) ==
            'face') {
          return toCertificationFace<T>(
            arguments: _normalizeCertificationPayloadArguments(arguments),
          );
        }
        if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ) ==
            'personal') {
          return toCertificationPersonalInfo<T>(arguments: arguments);
        }
        if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ) ==
            'job') {
          return toCertificationWorkInfo<T>(arguments: arguments);
        }
        if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ) ==
            'ext') {
          return toCertificationContactInfo<T>(arguments: arguments);
        }
        if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ) ==
            'emergent') {
          return toCertificationContactInfo<T>(arguments: arguments);
        }
        if (NavigationTargetMapper.isCertificationStepRouteKey(rawPage)) {
          return toCertificationStep<T>(
            routeKey: NavigationTargetMapper.normalizeProductDetailAuthItemCode(
              rawPage,
            ),
            arguments: _unwrapCertificationPayload(arguments),
          );
        }
        return null;
    }
  }

  static Future<T?>? _toNamedAfterPruningCertificationFlow<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return Get.offNamedUntil<T>(
      routeName,
      (route) =>
          !_certificationFlowPrunedRouteNames.contains(route.settings.name),
      arguments: arguments,
    );
  }

  static Map<String, dynamic> _normalizeCertificationPayloadArguments(
    Object? arguments,
  ) {
    final routeArguments = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : <String, dynamic>{};
    final payload = routeArguments['payload'];
    if (payload is Map) {
      return routeArguments;
    }
    return <String, dynamic>{'payload': routeArguments};
  }

  static Object? _unwrapCertificationPayload(Object? arguments) {
    if (arguments is! Map) {
      return arguments;
    }
    final routeArguments = Map<String, dynamic>.from(arguments);
    final payload = routeArguments['payload'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return routeArguments;
  }
}
