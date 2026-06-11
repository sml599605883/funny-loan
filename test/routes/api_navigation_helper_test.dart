import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';
import 'package:funny_loan/app/network/api/api_service.dart';
import 'package:funny_loan/app/network/client/network_client.dart';
import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/network/core/auth_expiry_guard.dart';
import 'package:funny_loan/app/network/core/common_params_provider.dart';
import 'package:funny_loan/app/network/core/response_parser.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/network/models/network_response.dart';
import 'package:funny_loan/app/network/utils/crypto_util.dart';
import 'package:funny_loan/app/routes/app_routes.dart';
import 'package:funny_loan/app/routes/api_navigation_helper.dart';
import 'package:funny_loan/app/routes/navigation_target_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiNavigationHelper', () {
    const permissionChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );

    setUp(() async {
      Get.reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permissionChannel, (call) async {
            switch (call.method) {
              case 'checkServiceStatus':
                return 1;
              case 'requestPermissions':
                return <int, int>{5: 1};
              default:
                return null;
            }
          });
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

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permissionChannel, null);
    });

    test('resolves recredit scheme to app page decision', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 302,
          'sidearms': 'gold://pocket/recredit',
          'outcrop': 0,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeAppPage);
      expect(decision['normalizedAppPage'], NavigationTargetMapper.recredit);
      expect(decision['isNative'], isTrue);
    });

    test('resolves Unbosomed scheme with cohabiter to product detail page', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 302,
          'sidearms': 'ph://funny-loan/ios/Unbosomed?cohabiter=2',
          'outcrop': 0,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeAppPage);
      expect(
        decision['normalizedAppPage'],
        NavigationTargetMapper.productDetail,
      );
      expect(
        decision['rawTarget'],
        'ph://funny-loan/ios/Unbosomed?cohabiter=2',
      );
    });

    test('resolves http target to web url decision', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 505,
          'sidearms': 'http://example.com/#/errorUrl?productId=1',
          'outcrop': 1,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeWebUrl);
      expect(
        (decision['webUrl'] as Uri?)?.toString(),
        'http://example.com/#/errorUrl?productId=1',
      );
      expect(decision['isNative'], isFalse);
    });

    test('resolves relative h5 target with explicit web base url', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 302,
          'sidearms': '/#/ShowedJagger?productId=1',
          'outcrop': 1,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeWebUrl);
      expect(
        (decision['webUrl'] as Uri?)?.toString(),
        'http://47.80.83.200/#/ShowedJagger?productId=1',
      );
    });

    test('parses and normalizes product detail auth items and next step', () {
      final payload = ApiNavigationHelper.parseProductDetail(
        Json(<String, dynamic>{
          'accretes': <String, dynamic>{
            'isolines': '1',
            'disprovable': 'Super Prestamo',
            'rejectee': '302021063003045300522743',
          },
          'oocytes': <Map<String, dynamic>>[
            <String, dynamic>{
              'hazinesses': 'Informasi identitas',
              'rutherfordiums': 'public',
              'sidearms': '',
              'outcrop': 0,
              'fleshed': 1,
            },
            <String, dynamic>{
              'hazinesses': 'Living Recognition',
              'rutherfordiums': 'accumulators',
              'sidearms': '',
              'outcrop': 0,
              'fleshed': 1,
            },
          ],
          'tetragrammaton': <String, dynamic>{
            'rutherfordiums': 'PaterInstallers',
            'sidearms': '',
            'outcrop': 0,
            'hazinesses': 'Identifying information',
          },
          'scabiosa': <String, dynamic>{
            'beveling': 'identity top',
            'vicomtes': 'identity success top',
            'extricating': 'face top',
            'verves': 'personal top',
            'presumably': 'job top',
            'wolframite': 'contact top',
            'cytokinetic': 'bank top',
            'omitted': 'bank bottom',
          },
        }),
      );

      final authItems = payload['authItems'] as List<dynamic>;

      expect(payload['productId'], '1');
      expect(payload['productName'], 'Super Prestamo');
      expect(payload['orderNo'], '302021063003045300522743');
      expect((authItems.first as Map<String, dynamic>)['routeKey'], 'public');
      expect((authItems.last as Map<String, dynamic>)['routeKey'], 'face');
      expect(payload['nextStepCode'], '');
      expect(payload['nextStepTitle'], 'Identifying information');
      expect(payload['nextStepTarget'], 'PaterInstallers');
      expect(payload['scabiosa'], <String, String>{
        'beveling': 'identity top',
        'vicomtes': 'identity success top',
        'extricating': 'face top',
        'verves': 'personal top',
        'presumably': 'job top',
        'wolframite': 'contact top',
        'cytokinetic': 'bank top',
        'omitted': 'bank bottom',
      });
      expect(
        ApiNavigationHelper.getCachedProductDetailScabiosa(),
        <String, String>{
          'beveling': 'identity top',
          'vicomtes': 'identity success top',
          'extricating': 'face top',
          'verves': 'personal top',
          'presumably': 'job top',
          'wolframite': 'contact top',
          'cytokinetic': 'bank top',
          'omitted': 'bank bottom',
        },
      );
    });

    testWidgets('applyProductAndNavigate uses sidearms first when present', (
      tester,
    ) async {
      final apiService = _FakeApiService(
        applyResponseData: const <String, dynamic>{
          'sidearms': 'http://example.com/apply-success',
          'gewurztraminers': 500,
          'outcrop': 1,
        },
      );
      Get.put<ApiService>(apiService, permanent: true);
      await tester.pumpWidget(_buildTestApp());
      String? launchedUrl;

      await ApiNavigationHelper.applyProductAndNavigate(
        'product-1',
        urlLauncher: (uri) async {
          launchedUrl = uri.toString();
          return true;
        },
      );

      expect(apiService.appliedProductBody, <String, dynamic>{
        'cohabiter': 'product-1',
      });
      expect(launchedUrl, 'http://example.com/apply-success');
    });

    testWidgets(
      'applyProductAndNavigate falls back to product detail when sidearms is empty and code is 200',
      (tester) async {
        final apiService = _FakeApiService(
          applyResponseData: const <String, dynamic>{
            'sidearms': '',
            'gewurztraminers': 200,
          },
          productDetailResponseData: const <String, dynamic>{
            'gewurztraminers': 200,
            'reallot': '',
            'accretes': <String, dynamic>{
              'isolines': 'product-1',
              'disprovable': 'Funny Loan',
              'rejectee': 'order-1',
            },
            'oocytes': <dynamic>[],
            'tetragrammaton': <String, dynamic>{
              'rutherfordiums': 'personal',
              'sidearms': '',
              'outcrop': 0,
              'hazinesses': 'Personal information',
            },
            'scabiosa': <String, dynamic>{},
          },
        );
        Get.put<ApiService>(apiService, permanent: true);
        await tester.pumpWidget(_buildTestApp());

        await ApiNavigationHelper.applyProductAndNavigate('product-1');
        await tester.pumpAndSettle();

        expect(apiService.fetchedProductDetailBody, <String, dynamic>{
          'cohabiter': 'product-1',
        });
        expect(find.text('personal page'), findsOneWidget);
      },
    );

    testWidgets('applyProductAndNavigate toasts reallot on failure', (
      tester,
    ) async {
      Get.put<ApiService>(
        _FakeApiService(
          applyResponseData: const <String, dynamic>{
            'sidearms': '',
            'gewurztraminers': 500,
            'reallot': 'apply failed',
          },
        ),
        permanent: true,
      );
      await tester.pumpWidget(_buildTestApp());

      await ApiNavigationHelper.applyProductAndNavigate('product-1');
      await tester.pumpAndSettle();

      expect(find.text('apply failed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
      'fetchProductDetailByProductId jumps by tetragrammaton rutherfordiums first',
      (tester) async {
        final apiService = _FakeApiService(
          productDetailResponseData: const <String, dynamic>{
            'gewurztraminers': 200,
            'reallot': '',
            'accretes': <String, dynamic>{
              'isolines': 'product-1',
              'disprovable': 'Funny Loan',
              'rejectee': 'order-1',
            },
            'oocytes': <dynamic>[],
            'tetragrammaton': <String, dynamic>{
              'rutherfordiums': 'personal',
              'sidearms': '',
              'outcrop': 0,
              'hazinesses': 'Personal information',
            },
            'scabiosa': <String, dynamic>{},
          },
        );
        Get.put<ApiService>(apiService, permanent: true);
        await tester.pumpWidget(_buildTestApp());

        await ApiNavigationHelper.fetchProductDetailByProductId('product-1');
        await tester.pumpAndSettle();

        expect(apiService.fetchedProductDetailBody, <String, dynamic>{
          'cohabiter': 'product-1',
        });
        expect(find.text('personal page'), findsOneWidget);
        final arguments = Get.arguments as Map<dynamic, dynamic>;
        final payload = arguments['payload'] as Map<dynamic, dynamic>;
        expect(payload['productId'], 'product-1');
        expect(payload['nextStepTitle'], 'Personal information');
      },
    );

    testWidgets(
      'fetchProductDetailByProductId follows order redirect when tetragrammaton is empty and code is 200',
      (tester) async {
        final apiService = _FakeApiService(
          productDetailResponseData: const <String, dynamic>{
            'gewurztraminers': 200,
            'reallot': '',
            'accretes': <String, dynamic>{
              'isolines': 'product-1',
              'disprovable': 'Funny Loan',
              'rejectee': 'order-1',
            },
            'oocytes': <dynamic>[],
            'tetragrammaton': <String, dynamic>{},
            'scabiosa': <String, dynamic>{},
          },
          orderRedirectResponseData: const <String, dynamic>{
            'sidearms': 'http://example.com/order-redirect',
            'outcrop': 1,
            'reallot': '',
          },
        );
        Get.put<ApiService>(apiService, permanent: true);
        await tester.pumpWidget(_buildTestApp());
        String? launchedUrl;

        await ApiNavigationHelper.fetchProductDetailByProductId(
          'product-1',
          urlLauncher: (uri) async {
            launchedUrl = uri.toString();
            return true;
          },
        );

        expect(apiService.fetchedOrderRedirectBody, <String, dynamic>{
          'orderNo': 'order-1',
        });
        expect(launchedUrl, 'http://example.com/order-redirect');
      },
    );

    testWidgets('fetchProductDetailByProductId toasts reallot on failure', (
      tester,
    ) async {
      Get.put<ApiService>(
        _FakeApiService(
          productDetailResponseData: const <String, dynamic>{
            'gewurztraminers': 500,
            'reallot': 'detail failed',
            'accretes': <String, dynamic>{
              'isolines': 'product-1',
              'disprovable': 'Funny Loan',
              'rejectee': 'order-1',
            },
            'oocytes': <dynamic>[],
            'tetragrammaton': <String, dynamic>{},
            'scabiosa': <String, dynamic>{},
          },
        ),
        permanent: true,
      );
      await tester.pumpWidget(_buildTestApp());

      await ApiNavigationHelper.fetchProductDetailByProductId('product-1');
      await tester.pumpAndSettle();

      expect(find.text('detail failed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

Widget _buildTestApp() {
  return GetMaterialApp(
    builder: (context, child) {
      final easyLoadingBuilder = EasyLoading.init();
      return easyLoadingBuilder(context, child);
    },
    home: const Scaffold(body: Text('home')),
    getPages: <GetPage<dynamic>>[
      GetPage(
        name: AppRoutes.login,
        page: () => const Scaffold(body: Text('login page')),
      ),
      GetPage(
        name: AppRoutes.certificationPersonalInfo,
        page: () => const Scaffold(body: Text('personal page')),
      ),
      GetPage(
        name: AppRoutes.detail,
        page: () => const Scaffold(body: Text('detail page')),
      ),
    ],
  );
}

class _FakeApiService extends ApiService {
  _FakeApiService({
    this.applyResponseData = const <String, dynamic>{},
    this.productDetailResponseData = const <String, dynamic>{},
    this.orderRedirectResponseData = const <String, dynamic>{},
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

  final Map<String, dynamic> applyResponseData;
  final Map<String, dynamic> productDetailResponseData;
  final Map<String, dynamic> orderRedirectResponseData;
  Map<String, dynamic> appliedProductBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedProductDetailBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedOrderRedirectBody = const <String, dynamic>{};

  @override
  Future<NetworkResponse> applyProduct(Map<String, dynamic> body) async {
    appliedProductBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(applyResponseData),
      raw: applyResponseData,
    );
  }

  @override
  Future<NetworkResponse> fetchProductDetail(Map<String, dynamic> body) async {
    fetchedProductDetailBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(productDetailResponseData),
      raw: productDetailResponseData,
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
