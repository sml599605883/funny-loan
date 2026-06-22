import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/modules/home/controllers/home_controller.dart';
import 'package:funny_loan/app/modules/home/models/app_home_model.dart';
import 'package:funny_loan/app/modules/home/models/home_popup_data.dart';
import 'package:funny_loan/app/modules/home/views/widgets/home_popup.dart';
import 'package:funny_loan/app/network/api/api_service.dart';
import 'package:funny_loan/app/network/client/network_client.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/network/core/auth_expiry_guard.dart';
import 'package:funny_loan/app/network/core/common_params_provider.dart';
import 'package:funny_loan/app/network/core/response_parser.dart';
import 'package:funny_loan/app/network/models/network_response.dart';
import 'package:funny_loan/app/network/utils/crypto_util.dart';
import 'package:funny_loan/app/routes/app_routes.dart';
import 'package:funny_loan/app/theme/screen_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('home refresh requests popup after home data refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        builder: EasyLoading.init(),
        home: const SizedBox.shrink(),
      ),
    );
    final apiService = _FakeApiService();
    final controller = HomeController();

    controller.onNetworkReady(apiService);
    await tester.pump();
    apiService.calls.clear();
    await controller.fetchHomeData();

    expect(apiService.calls, <String>['home', 'popup']);
    expect(apiService.popupParams, <String, dynamic>{'interferons': 1});
  });

  testWidgets('home refresh shows upgrade popup', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return EasyLoading.init()(context, child);
        },
        home: const SizedBox.shrink(),
      ),
    );
    final apiService = _FakeApiService(
      popupResponseData: const <String, dynamic>{
        'outcrop': 1,
        'fidelismo': <String, dynamic>{
          'hysterically': '1.2.3',
          'duchesses': 'Improve loan application experience',
          'sidearms': 'https://example.test/update',
        },
      },
    );
    final controller = HomeController();

    controller.onNetworkReady(apiService);
    await tester.pump();
    await tester.pump();

    expect(find.byType(UpgradePopupContent), findsOneWidget);
    expect(find.text('New version released'), findsOneWidget);
    expect(find.text('V1.2.3'), findsOneWidget);
    expect(find.text('Improve loan application experience'), findsOneWidget);
  });

  testWidgets('upgrade popup opens target url externally', (tester) async {
    Uri? openedUri;
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return child ?? const SizedBox.shrink();
        },
        home: Scaffold(
          body: UpgradePopupContent(
            data: const HomePopupData(
              type: HomePopupType.appUpgrade,
              latestVersion: '1.2.3',
              content: 'Improve loan application experience',
              targetUrl: 'https://example.test/update',
            ),
            externalOpener: (uri) async {
              openedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(HomePopup.upgradeButtonKey));
    await tester.pumpAndSettle();

    expect(openedUri?.toString(), 'https://example.test/update');
  });

  testWidgets('home refresh shows marketing popup for outcrop 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return EasyLoading.init()(context, child);
        },
        home: const SizedBox.shrink(),
      ),
    );
    final apiService = _FakeApiService(
      popupResponseData: const <String, dynamic>{
        'outcrop': 3,
        'fidelismo': <String, dynamic>{
          'dizzyingly': 'https://example.test/marketing.png',
          'sidearms': 'https://example.test/marketing',
        },
      },
    );
    final controller = HomeController();

    controller.onNetworkReady(apiService);
    await tester.pump();
    await tester.pump();

    expect(find.byType(MarketingPopupContent), findsOneWidget);
    expect(find.byKey(HomePopup.marketingImageKey), findsOneWidget);
  });

  testWidgets('marketing popup opens target url in app', (tester) async {
    String? openedUrl;
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return child ?? const SizedBox.shrink();
        },
        home: Scaffold(
          body: MarketingPopupContent(
            data: const HomePopupData(
              type: HomePopupType.marketing,
              imageUrl: 'https://example.test/marketing.png',
              targetUrl: 'https://example.test/marketing',
            ),
            inAppOpener: (url) {
              openedUrl = url;
            },
          ),
        ),
      ),
    );

    final gesture = tester.widget<GestureDetector>(
      find.byKey(HomePopup.marketingImageKey),
    );
    gesture.onTap?.call();
    await tester.pumpAndSettle();

    expect(openedUrl, 'https://example.test/marketing');
  });

  testWidgets('home refresh ignores unsupported popup type', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return EasyLoading.init()(context, child);
        },
        home: const SizedBox.shrink(),
      ),
    );
    final apiService = _FakeApiService(
      popupResponseData: const <String, dynamic>{
        'outcrop': 2,
        'fidelismo': <String, dynamic>{},
      },
    );
    final controller = HomeController();

    controller.onNetworkReady(apiService);
    await tester.pump();
    await tester.pump();

    expect(find.byType(UpgradePopupContent), findsNothing);
    expect(find.byType(MarketingPopupContent), findsNothing);
  });

  testWidgets('banner tap uploads click record and opens target', (
    tester,
  ) async {
    Map<String, dynamic>? webViewArguments;
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return EasyLoading.init()(context, child);
        },
        home: const SizedBox.shrink(),
        getPages: <GetPage<dynamic>>[
          GetPage(
            name: AppRoutes.webview,
            page: () {
              final arguments = Get.arguments;
              webViewArguments = arguments is Map
                  ? Map<String, dynamic>.from(arguments)
                  : const <String, dynamic>{};
              return const Scaffold(body: Text('webview'));
            },
          ),
        ],
      ),
    );
    final apiService = _FakeApiService();
    final controller = HomeController();
    controller.onNetworkReady(apiService);
    await tester.pump();

    await controller.handleBannerTap(
      const HomeBannerModel(
        raw: <String, dynamic>{},
        id: 'banner-2',
        imageUrl: 'https://example.test/banner.png',
        linkUrl: 'https://example.test/banner',
      ),
    );
    await tester.pumpAndSettle();

    expect(apiService.uploadedBannerClickBody, <String, dynamic>{
      'mislodges': 'banner-2',
    });
    expect(webViewArguments, <String, dynamic>{
      'url': 'https://example.test/banner',
    });
  });

  testWidgets('order status tap opens process target', (tester) async {
    Map<String, dynamic>? webViewArguments;
    Get.put<MutableNetworkState>(
      MutableNetworkState(apiBaseUrl: '', webBaseUrl: 'https://web.test'),
      permanent: true,
    );
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          return EasyLoading.init()(context, child);
        },
        home: const SizedBox.shrink(),
        getPages: <GetPage<dynamic>>[
          GetPage(
            name: AppRoutes.webview,
            page: () {
              final arguments = Get.arguments;
              webViewArguments = arguments is Map
                  ? Map<String, dynamic>.from(arguments)
                  : const <String, dynamic>{};
              return const Scaffold(body: Text('webview'));
            },
          ),
        ],
      ),
    );
    final controller = HomeController();

    await controller.handleOrderStatusTap(
      const HomeProcessModel(
        raw: <String, dynamic>{},
        productId: 'product-1',
        orderNo: 'order-1',
        linkUrl: 'https://example.test/status-target',
      ),
    );
    await tester.pumpAndSettle();

    expect(webViewArguments, <String, dynamic>{
      'url': 'https://example.test/status-target',
    });
  });
}

class _FakeApiService extends ApiService {
  _FakeApiService({
    this.popupResponseData = const <String, dynamic>{
      'outcrop': 0,
      'fidelismo': <String, dynamic>{},
    },
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

  final calls = <String>[];
  final Map<String, dynamic> popupResponseData;
  Map<String, dynamic>? popupParams;
  Map<String, dynamic>? uploadedBannerClickBody;

  @override
  Future<NetworkResponse> fetchAppHome(Map<String, dynamic> params) async {
    calls.add('home');
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(<String, dynamic>{}),
      raw: const <String, dynamic>{},
    );
  }

  @override
  Future<NetworkResponse> fetchPopup(Map<String, dynamic> params) async {
    calls.add('popup');
    popupParams = Map<String, dynamic>.from(params);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(popupResponseData),
      raw: popupResponseData,
    );
  }

  @override
  Future<NetworkResponse> uploadBannerClickRecord(
    Map<String, dynamic> body,
  ) async {
    uploadedBannerClickBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(<String, dynamic>{}),
      raw: const <String, dynamic>{},
    );
  }
}
