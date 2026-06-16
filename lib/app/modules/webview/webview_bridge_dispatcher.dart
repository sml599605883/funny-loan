import 'package:funny_loan/app/network/errors/network_error_mapper.dart';

import '../../core/native/native_bridge.dart';
import '../../core/json/json.dart';
import '../../network/api/api_service.dart';
import '../../network/network_module.dart';
import '../../report/report_manager.dart';
import '../../routes/api_navigation_helper.dart';
import '../../routes/navigation_helper.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

enum WebViewBridgeAction {
  uploadRisk,
  openExternalBrowser,
  openUrl,
  closePage,
  goHome,
  toGrade,
  retryOrder,
  changeAccount,
  getPublicParams,
  unsupported,
}

class WebViewBridgeRequest {
  WebViewBridgeRequest({
    required this.action,
    Json? data,
    this.callback,
    this.rawMessage = '',
  }) : data = data ?? Json(<String, dynamic>{});

  factory WebViewBridgeRequest.fromMessage(dynamic message) {
    final json = message is String ? Json.parse(message) : Json(message);
    final actionValue = json['action'].stringValue.trim().isNotEmpty
        ? json['action'].stringValue.trim()
        : json['method'].stringValue.trim();
    return WebViewBridgeRequest(
      action: WebViewBridgeActionX.fromRaw(actionValue),
      data: json['data'],
      callback:
          json['callback'].stringOrNull?.trim() ??
          json['callbackId'].stringOrNull?.trim(),
      rawMessage: json.rawString(),
    );
  }

  final WebViewBridgeAction action;
  final Json data;
  final String? callback;
  final String rawMessage;
}

extension WebViewBridgeActionX on WebViewBridgeAction {
  static WebViewBridgeAction fromRaw(String rawAction) {
    switch (rawAction.trim()) {
      case 'funny_loan_ehjDgwoW4zPWQ3a':
        return WebViewBridgeAction.uploadRisk;
      case 'funny_loan_wlxa8eauNT2W09N':
        return WebViewBridgeAction.openExternalBrowser;
      case 'funny_loan_d2ayej1pMyRIQsi':
        return WebViewBridgeAction.openUrl;
      case 'funny_loan_L4vkZvEjZiRkEG8':
        return WebViewBridgeAction.closePage;
      case 'funny_loan_VqYC7ZnNKMSymiK':
        return WebViewBridgeAction.goHome;
      case 'funny_loan_i2QVBh8rv3SeVky':
        return WebViewBridgeAction.toGrade;
      case 'funny_loan_SvmXa7766ceTANO':
        return WebViewBridgeAction.retryOrder;
      case 'funny_loan_XpRsQGeB5cl54PY':
        return WebViewBridgeAction.changeAccount;
      case 'funny_loan_IZqKAOAYtuyHub9':
        return WebViewBridgeAction.getPublicParams;
      default:
        return WebViewBridgeAction.unsupported;
    }
  }
}

class WebViewBridgeDispatchResult {
  const WebViewBridgeDispatchResult({
    required this.success,
    this.callback,
    this.callbackData = const <String, dynamic>{},
    this.errorMessage = '',
  });

  final bool success;
  final String? callback;
  final Map<String, dynamic> callbackData;
  final String errorMessage;
}

typedef BrowserLauncher = Future<bool> Function(Uri uri);
typedef ReviewRequester = Future<bool> Function();
typedef OpenUrlHandler = Future<void> Function(String rawTarget);
typedef ClosePageHandler = void Function();
typedef GoHomeHandler = Future<void> Function();
typedef RiskReporter = Future<void> Function(Json payload);
typedef ChangeAccountOpener =
    Future<void> Function(Map<String, dynamic> arguments);

class WebViewBridgeDispatcher {
  WebViewBridgeDispatcher({
    BrowserLauncher? openExternalBrowser,
    OpenUrlHandler? openUrl,
    ReviewRequester? requestAppReview,
    ClosePageHandler? closePage,
    GoHomeHandler? goHome,
    RiskReporter? reportRisk,
    ChangeAccountOpener? openCardList,
    ChangeAccountOpener? openBindCard,
  }) : _openExternalBrowser =
           openExternalBrowser ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)),
       _openUrl = openUrl ?? _defaultOpenUrl,
       _requestAppReview = requestAppReview ?? NativeBridge.requestAppReview,
       _closePage = closePage ?? (() => NavigationHelper.back<void>()),
       _goHome =
           goHome ?? (() async => NavigationHelper.offAllToAppHome<void>()),
       _reportRisk = reportRisk ?? _defaultReportRisk,
       _openCardList = openCardList ?? _defaultOpenCardList,
       _openBindCard = openBindCard ?? _defaultOpenBindCard;

  final BrowserLauncher _openExternalBrowser;
  final OpenUrlHandler _openUrl;
  final ReviewRequester _requestAppReview;
  final ClosePageHandler _closePage;
  final GoHomeHandler _goHome;
  final RiskReporter _reportRisk;
  final ChangeAccountOpener _openCardList;
  final ChangeAccountOpener _openBindCard;

  Future<WebViewBridgeDispatchResult> dispatch(
    WebViewBridgeRequest request,
  ) async {
    switch (request.action) {
      case WebViewBridgeAction.uploadRisk:
        await _reportRisk(request.data);
        return const WebViewBridgeDispatchResult(success: true);
      case WebViewBridgeAction.openExternalBrowser:
        final uri = Uri.tryParse(request.data.stringValue);
        if (uri == null) {
          return const WebViewBridgeDispatchResult(
            success: false,
            errorMessage: 'Missing url',
          );
        }
        final opened = await _openExternalBrowser(uri);
        return WebViewBridgeDispatchResult(
          success: opened,
          errorMessage: opened ? '' : 'Unable to open external browser',
        );
      case WebViewBridgeAction.openUrl:
        final rawTarget = request.data.stringValue.trim();
        if (rawTarget.isEmpty) {
          return const WebViewBridgeDispatchResult(
            success: false,
            errorMessage: 'Missing url',
          );
        }
        await _openUrl(rawTarget);
        return const WebViewBridgeDispatchResult(success: true);
      case WebViewBridgeAction.closePage:
        _closePage();
        return const WebViewBridgeDispatchResult(success: true);
      case WebViewBridgeAction.goHome:
        await _goHome();
        return const WebViewBridgeDispatchResult(success: true);
      case WebViewBridgeAction.toGrade:
        final success = await _requestAppReview();
        return WebViewBridgeDispatchResult(
          success: success,
          errorMessage: success ? '' : 'Unable to request app review',
        );
      case WebViewBridgeAction.retryOrder:
        final orderNo = request.data['rejectee'].stringValue.trim();
        if (orderNo.isNotEmpty && Get.isRegistered<ApiService>()) {
          await Get.find<ApiService>().fetchOrderRedirect(<String, dynamic>{
            'nosh': orderNo,
          });
        }
        return const WebViewBridgeDispatchResult(success: true);
      case WebViewBridgeAction.changeAccount:
        final productId = request.data['skoals'].stringValue.trim();
        final orderNo = request.data['rejectee'].stringValue.trim();
        if (productId.isNotEmpty && Get.isRegistered<ApiService>()) {
          try {
            final response = await Get.find<ApiService>().fetchUserAccountList(
              <String, dynamic>{'cohabiter': productId},
            );
            final keelboat = response.data['keelboat'].listValue;
            final arguments = <String, dynamic>{
              'productId': productId,
              'orderNo': orderNo,
              'ischange': true,
              'keelboat': keelboat,
            };
            if (keelboat.isNotEmpty) {
              await _openCardList(arguments);
            } else {
              await _openBindCard(arguments);
            }
            return const WebViewBridgeDispatchResult(success: true);
          } catch (e) {
            return WebViewBridgeDispatchResult(
              success: false,
              errorMessage: NetworkErrorMapper.map(e),
            );
          }
        }
        return const WebViewBridgeDispatchResult(success: false);
      case WebViewBridgeAction.getPublicParams:
        final params = await _loadQueryParametersForTarget(
          request.data.stringValue,
        );
        return WebViewBridgeDispatchResult(
          success: true,
          callback: request.callback,
          callbackData: params,
        );
      case WebViewBridgeAction.unsupported:
        return const WebViewBridgeDispatchResult(
          success: false,
          errorMessage: 'Unsupported action',
        );
    }
  }

  static Future<void> _defaultOpenUrl(String rawTarget) async {
    await ApiNavigationHelper.navigateRawTarget(rawTarget);
  }

  static Future<Map<String, dynamic>> _loadQueryParametersForTarget(
    String rawTarget,
  ) async {
    if (Get.isRegistered<NetworkModule>()) {
      if (rawTarget.isEmpty) {
        return const <String, dynamic>{};
      }
      final uri = Uri.tryParse(rawTarget);
      final path = uri?.path.trim() ?? '';
      if (path.isEmpty) {
        return const <String, dynamic>{};
      }
      return Get.find<NetworkModule>().buildQueryParameters(
        path,
        businessParams: uri?.queryParameters ?? const <String, dynamic>{},
      );
    }
    return const <String, dynamic>{};
  }

  static Future<void> _defaultReportRisk(Json payload) async {
    if (Get.isRegistered<ReportManager>()) {
      await Get.find<ReportManager>().reportRiskScene(
        sceneType: ReportRiskScene.webViewRisk,
        productId: payload['skoals'].stringValue.trim(),
        orderNo: payload['rejectee'].stringValue.trim(),
        startTime: _currentSecondsTimestamp(),
      );
      return;
    }
    if (!Get.isRegistered<ApiService>()) {
      return;
    }
    await Get.find<ApiService>().reportRiskEvent(payload.mapValue);
  }

  static String _currentSecondsTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }

  static Future<void> _defaultOpenCardList(
    Map<String, dynamic> arguments,
  ) async {
    NavigationHelper.toCardList(arguments: arguments);
  }

  static Future<void> _defaultOpenBindCard(
    Map<String, dynamic> arguments,
  ) async {
    NavigationHelper.toCertificationBindCard(
      routeKey: 'bank',
      arguments: <String, dynamic>{'payload': arguments},
    );
  }
}
