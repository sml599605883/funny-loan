import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/modules/card_list/views/card_list_page.dart';
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
  tearDown(Get.reset);

  testWidgets('add payment method opens bind card with product and order', (
    WidgetTester tester,
  ) async {
    Map<String, dynamic>? bindCardArguments;

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          final easyLoadingBuilder = EasyLoading.init();
          return easyLoadingBuilder(context, child);
        },
        home: const Scaffold(body: SizedBox.shrink()),
        getPages: <GetPage<dynamic>>[
          GetPage(name: AppRoutes.cardList, page: () => const CardListPage()),
          GetPage(
            name: AppRoutes.certificationBindCard,
            page: () {
              final arguments = Get.arguments;
              bindCardArguments = arguments is Map
                  ? Map<String, dynamic>.from(arguments)
                  : const <String, dynamic>{};
              return const Scaffold(body: Text('Bind card recorder'));
            },
          ),
        ],
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.cardList,
      arguments: <String, dynamic>{
        'productId': 'product-123',
        'orderNo': 'order-456',
        'ischange': true,
        'keelboat': const <Map<String, dynamic>>[],
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add other payment methods'));
    await tester.pumpAndSettle();

    expect(find.text('Bind card recorder'), findsOneWidget);
    expect(bindCardArguments, <String, dynamic>{
      'routeKey': 'bank',
      'payload': <String, dynamic>{
        'productId': 'product-123',
        'orderNo': 'order-456',
        'ischange': true,
      },
    });
  });

  testWidgets('submit changes selected card and opens returned webview', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      changeBankCardResponseData: const <String, dynamic>{
        'copybooks': 'https://example.test/card-change-result',
      },
    );
    Get.put<ApiService>(apiService, permanent: true);
    Map<String, dynamic>? webViewArguments;

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) {
          ScreenAdapter.init(context);
          final easyLoadingBuilder = EasyLoading.init();
          return easyLoadingBuilder(context, child);
        },
        home: const Scaffold(body: SizedBox.shrink()),
        getPages: <GetPage<dynamic>>[
          GetPage(name: AppRoutes.cardList, page: () => const CardListPage()),
          GetPage(
            name: AppRoutes.webview,
            page: () {
              final arguments = Get.arguments;
              webViewArguments = arguments is Map
                  ? Map<String, dynamic>.from(arguments)
                  : const <String, dynamic>{};
              return const Scaffold(body: Text('Card change webview'));
            },
          ),
        ],
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.cardList,
      arguments: <String, dynamic>{
        'productId': 'product-123',
        'orderNo': 'order-456',
        'ischange': true,
        'keelboat': const <Map<String, dynamic>>[
          <String, dynamic>{
            'impotencies': 2,
            'intoxicated': '',
            'nemesis': 'Bank',
            'federalizes': <Map<String, dynamic>>[
              <String, dynamic>{
                'triaged': 9,
                'surly': '110',
                'mondos': 1,
                'euchromatic': '',
                'unappreciated': 'Banco Dipolog',
                'outcrop': 'BDI',
                'fleshed': 1,
                'cantilenas': '',
              },
            ],
          },
        ],
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiService.changedBankCardBody, <String, dynamic>{
      'nosh': 'order-456',
      'triaged': 9,
    });
    expect(find.text('Card change webview'), findsOneWidget);
    expect(webViewArguments, <String, dynamic>{
      'url': 'https://example.test/card-change-result',
    });
  });
}

class _FakeApiService extends ApiService {
  _FakeApiService({this.changeBankCardResponseData = const <String, dynamic>{}})
    : super(
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

  final Map<String, dynamic> changeBankCardResponseData;
  Map<String, dynamic> changedBankCardBody = const <String, dynamic>{};

  @override
  Future<NetworkResponse> changeBankCard(Map<String, dynamic> body) async {
    changedBankCardBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(changeBankCardResponseData),
      raw: changeBankCardResponseData,
    );
  }
}
