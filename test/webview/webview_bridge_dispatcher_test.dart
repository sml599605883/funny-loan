import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';
import 'package:funny_loan/app/modules/webview/webview_bridge_dispatcher.dart';
import 'package:funny_loan/app/network/api/api_service.dart';
import 'package:funny_loan/app/network/client/network_client.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/network/core/auth_expiry_guard.dart';
import 'package:funny_loan/app/network/core/common_params_provider.dart';
import 'package:funny_loan/app/network/core/response_parser.dart';
import 'package:funny_loan/app/network/models/network_response.dart';
import 'package:funny_loan/app/network/network_module.dart';
import 'package:funny_loan/app/network/utils/crypto_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewBridgeDispatcher', () {
    const nativeChannel = MethodChannel('funny_loan/native_bridge');
    const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

    setUp(() async {
      Get.reset();
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppDataStore.persistedTokenKey: 'token-1',
      });
      await AppDataStore.init();
      await AppDataStore.setPersistentString(
        AppDataStore.persistedTokenKey,
        'token-1',
      );
      Get.put<MutableNetworkState>(
        MutableNetworkState(
          apiBaseUrl: 'http://47.80.83.200/l-funny',
          webBaseUrl: 'http://47.80.83.200',
        ),
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlLauncherChannel, null);
    });

    test(
      'dispatches openUrl through ApiNavigationHelper with raw request data',
      () async {
        String? openedTarget;
        var openedExternalBrowser = false;

        final dispatcher = WebViewBridgeDispatcher(
          openUrl: (rawTarget) async {
            openedTarget = rawTarget;
          },
          openExternalBrowser: (uri) async {
            openedExternalBrowser = true;
            return true;
          },
        );

        final result = await dispatcher.dispatch(
          WebViewBridgeRequest(
            action: WebViewBridgeAction.openUrl,
            data: Json('cashloan://app/home'),
          ),
        );

        expect(result.success, isTrue);
        expect(openedExternalBrowser, isFalse);
        expect(openedTarget, 'cashloan://app/home');
      },
    );

    test('openExternalBrowser keeps using external browser launcher', () async {
      Uri? launchedUri;
      final dispatcher = WebViewBridgeDispatcher(
        openExternalBrowser: (uri) async {
          launchedUri = uri;
          return true;
        },
      );

      final result = await dispatcher.dispatch(
        WebViewBridgeRequest(
          action: WebViewBridgeAction.openExternalBrowser,
          data: Json('https://example.com/store'),
        ),
      );

      expect(result.success, isTrue);
      expect(launchedUri?.toString(), 'https://example.com/store');
    });

    test(
      'getPublicParams returns built queryParams from network module',
      () async {
        Get.put<NetworkModule>(
          _FakeNetworkModule(
            queryParams: const <String, dynamic>{
              'manioc': 'token-1',
              'expressionism': '1710000000000',
              'slipcase': 'signed-value',
              'cycloid': '123456',
              'productId': '1',
            },
          ),
          permanent: true,
        );
        final dispatcher = WebViewBridgeDispatcher();

        final result = await dispatcher.dispatch(
          WebViewBridgeRequest(
            action: WebViewBridgeAction.getPublicParams,
            callback: 'callbackFn',
            data: Json('http://47.80.83.200/#/ShowedJagger?productId=1'),
          ),
        );

        expect(result.success, isTrue);
        expect(result.callback, 'callbackFn');
        expect(result.callbackData['manioc'], 'token-1');
        expect(result.callbackData['slipcase'], 'signed-value');
        expect(result.callbackData['cycloid'], '123456');
        expect(result.callbackData['productId'], '1');
      },
    );

    test('routes app review through NativeBridge', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeChannel, (call) async {
            calls.add(call);
            return true;
          });
      final dispatcher = WebViewBridgeDispatcher();

      final result = await dispatcher.dispatch(
        WebViewBridgeRequest(action: WebViewBridgeAction.toGrade),
      );

      expect(result.success, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'requestAppReview');
    });

    test('accepts callbackId from H5 bridge payload', () {
      final request = WebViewBridgeRequest.fromMessage(<String, dynamic>{
        'action': 'funny_loan_IZqKAOAYtuyHub9',
        'callbackId': 'bridgeCb',
        'data': <String, dynamic>{'url': '/#/demo'},
      });

      expect(request.action, WebViewBridgeAction.getPublicParams);
      expect(request.callback, 'bridgeCb');
    });

    test('retryOrder posts orderNo from rejectee only', () async {
      final apiService = _FakeApiService(
        orderRedirectResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'sidearms': '/#/ShowedJagger?productId=1',
          },
          'unplait': '0',
          'gluteal': 'success',
        },
      );
      Get.put<ApiService>(apiService, permanent: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlLauncherChannel, (call) async {
            if (call.method == 'launch') {
              return true;
            }
            return null;
          });
      final dispatcher = WebViewBridgeDispatcher();

      final result = await dispatcher.dispatch(
        WebViewBridgeRequest(
          action: WebViewBridgeAction.retryOrder,
          data: Json(<String, dynamic>{'rejectee': 'order-1'}),
        ),
      );

      expect(result.success, isTrue);
      expect(apiService.fetchedOrderRedirectBody, <String, dynamic>{
        'nosh': 'order-1',
      });
    });

    test(
      'changeAccount opens card list when keelboat exists with product and order',
      () async {
        final apiService = _FakeApiService(
          userAccountListResponseData: const <String, dynamic>{
            'keelboat': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'bank-1'},
            ],
          },
        );
        Get.put<ApiService>(apiService, permanent: true);
        String? openedRoute;
        Map<String, dynamic>? openedArguments;
        final dispatcher = WebViewBridgeDispatcher(
          openCardList: (arguments) async {
            openedRoute = 'cardList';
            openedArguments = arguments;
          },
          openBindCard: (arguments) async {
            openedRoute = 'bindCard';
            openedArguments = arguments;
          },
        );

        final result = await dispatcher.dispatch(
          WebViewBridgeRequest(
            action: WebViewBridgeAction.changeAccount,
            data: Json(<String, dynamic>{
              'skoals': 'product-1',
              'rejectee': 'order-1',
            }),
          ),
        );

        expect(result.success, isTrue);
        expect(openedRoute, 'cardList');
        expect(openedArguments, <String, dynamic>{
          'productId': 'product-1',
          'orderNo': 'order-1',
          'ischange': true,
          'keelboat': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'bank-1'},
          ],
        });
        expect(apiService.fetchedUserAccountListBody, <String, dynamic>{
          'cohabiter': 'product-1',
        });
      },
    );

    test(
      'changeAccount opens bind card when keelboat is empty with product and order',
      () async {
        final apiService = _FakeApiService(
          userAccountListResponseData: const <String, dynamic>{
            'keelboat': <Map<String, dynamic>>[],
          },
        );
        Get.put<ApiService>(apiService, permanent: true);
        String? openedRoute;
        Map<String, dynamic>? openedArguments;
        final dispatcher = WebViewBridgeDispatcher(
          openCardList: (arguments) async {
            openedRoute = 'cardList';
            openedArguments = arguments;
          },
          openBindCard: (arguments) async {
            openedRoute = 'bindCard';
            openedArguments = arguments;
          },
        );

        final result = await dispatcher.dispatch(
          WebViewBridgeRequest(
            action: WebViewBridgeAction.changeAccount,
            data: Json(<String, dynamic>{
              'skoals': 'product-1',
              'rejectee': 'order-1',
            }),
          ),
        );

        expect(result.success, isTrue);
        expect(openedRoute, 'bindCard');
        expect(openedArguments, <String, dynamic>{
          'productId': 'product-1',
          'orderNo': 'order-1',
          'ischange': true,
          'keelboat': const <Map<String, dynamic>>[],
        });
        expect(apiService.fetchedUserAccountListBody, <String, dynamic>{
          'cohabiter': 'product-1',
        });
      },
    );

    test('changeAccount posts productId from skoals only', () async {
      final apiService = _FakeApiService();
      Get.put<ApiService>(apiService, permanent: true);
      String? openedRoute;
      Map<String, dynamic>? openedArguments;
      final dispatcher = WebViewBridgeDispatcher(
        openCardList: (arguments) async {
          openedRoute = 'cardList';
          openedArguments = arguments;
        },
        openBindCard: (arguments) async {
          openedRoute = 'bindCard';
          openedArguments = arguments;
        },
      );

      final result = await dispatcher.dispatch(
        WebViewBridgeRequest(
          action: WebViewBridgeAction.changeAccount,
          data: Json(<String, dynamic>{
            'skoals': 'product-1',
            'rejectee': 'order-1',
          }),
        ),
      );

      expect(result.success, isTrue);
      expect(apiService.fetchedUserAccountListBody, <String, dynamic>{
        'cohabiter': 'product-1',
      });
      expect(openedRoute, anyOf('cardList', 'bindCard'));
      expect(openedArguments, <String, dynamic>{
        'productId': 'product-1',
        'orderNo': 'order-1',
        'ischange': true,
        'keelboat': const <Map<String, dynamic>>[],
      });
    });
  });
}

class _FakeApiService extends ApiService {
  _FakeApiService({
    this.orderRedirectResponseData = const <String, dynamic>{},
    this.userAccountListResponseData = const <String, dynamic>{},
  }) : super(
         client: NetworkClient(
           dio: Dio(),
           config: _dummyConfig,
           state: MutableNetworkState(apiBaseUrl: '', webBaseUrl: ''),
           commonParamsProvider: CommonParamsProvider(_dummyConfig),
           responseParser: ResponseParser(
             config: _dummyConfig,
             authExpiryGuard: AuthExpiryGuard(_dummyConfig),
           ),
         ),
         cryptoUtil: const CryptoUtil(
           key: '1234567890abcdef',
           iv: 'abcdef1234567890',
         ),
       );

  static final NetworkConfig _dummyConfig = NetworkConfig.funnyLoanIos(
    defaultApiBaseUrl: '',
    defaultWebBaseUrl: '',
    remoteConfigUrl: '',
    signatureSecret: 'secret',
    cryptoKey: '1234567890abcdef',
    cryptoIv: 'abcdef1234567890',
  );

  final Map<String, dynamic> orderRedirectResponseData;
  final Map<String, dynamic> userAccountListResponseData;
  Map<String, dynamic> fetchedOrderRedirectBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedUserAccountListBody = const <String, dynamic>{};

  @override
  Future<NetworkResponse> fetchUserAccountList(
    Map<String, dynamic> body,
  ) async {
    fetchedUserAccountListBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(userAccountListResponseData),
      raw: userAccountListResponseData,
    );
  }

  @override
  Future<NetworkResponse> fetchOrderRedirect(Map<String, dynamic> body) async {
    fetchedOrderRedirectBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(orderRedirectResponseData),
      raw: orderRedirectResponseData,
    );
  }
}

class _FakeNetworkModule extends GetxService implements NetworkModule {
  _FakeNetworkModule({required this.queryParams});

  final Map<String, dynamic> queryParams;

  @override
  Future<Map<String, dynamic>> getCommonParams() async =>
      const <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> buildQueryParameters(
    String path, {
    Map<String, dynamic> businessParams = const <String, dynamic>{},
  }) async => queryParams;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
