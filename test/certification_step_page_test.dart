import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_step_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_upload_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_upload_success_page.dart';
import 'package:funny_loan/app/network/api/api_service.dart';
import 'package:funny_loan/app/network/client/network_client.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/network/core/auth_expiry_guard.dart';
import 'package:funny_loan/app/network/core/common_params_provider.dart';
import 'package:funny_loan/app/network/core/response_parser.dart';
import 'package:funny_loan/app/network/errors/network_exception.dart';
import 'package:funny_loan/app/network/models/network_response.dart';
import 'package:funny_loan/app/network/utils/crypto_util.dart';
import 'package:funny_loan/app/routes/app_routes.dart';
import 'package:funny_loan/app/theme/screen_adapter.dart';

void main() {
  tearDown(() {
    Get.reset();
  });

  testWidgets('identity verification page renders first lightnings group', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: <String, dynamic>{
          'lightnings': <List<String>>[
            <String>['PRC ID', 'SSS ID'],
          ],
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationStep,
      arguments: <String, dynamic>{
        'routeKey': 'public',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('PRC ID'), findsOneWidget);
    expect(find.text('SSS ID'), findsOneWidget);
    expect(find.text('Other Options'), findsNothing);
  });

  testWidgets('identity verification page switches between id type groups', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: <String, dynamic>{
          'lightnings': <List<String>>[
            <String>['PRC ID', 'SSS ID'],
            <String>["DRIVER'S LICENSE", 'TIN ID'],
          ],
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationStep,
      arguments: <String, dynamic>{
        'routeKey': 'public',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('PRC ID'), findsOneWidget);
    expect(find.text("DRIVER'S LICENSE"), findsNothing);

    await tester.tap(find.text('Other Options'));
    await tester.pumpAndSettle();

    expect(find.text("DRIVER'S LICENSE"), findsOneWidget);
    expect(find.text('PRC ID'), findsNothing);
  });

  testWidgets('identity verification page opens upload page after selection', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: <String, dynamic>{
          'lightnings': <List<String>>[
            <String>['PRC ID'],
          ],
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationStep,
      arguments: <String, dynamic>{
        'routeKey': 'public',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('PRC ID'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('Snap your valid ID Clear photo, quick check'),
      findsOneWidget,
    );
    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('PRC ID'), findsNothing);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Photograph'), findsOneWidget);
    expect(find.text('Photo Album'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('identity upload page renders independently', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationUpload,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{'nextStepTitle': 'Identity verification'},
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Identity verification'), findsOneWidget);
    expect(
      find.text('Snap your valid ID Clear photo, quick check'),
      findsOneWidget,
    );
    expect(find.text('Submit'), findsOneWidget);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Photograph'), findsOneWidget);
    expect(find.text('Photo Album'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('identity upload page uploads selected album image', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
    );
    Get.put<ApiService>(apiService, permanent: true);

    await tester.pumpWidget(
      _buildTestApp(
        uploadImagePicker: _FakeUploadImagePicker(
          galleryFilePath: '/tmp/id-front.png',
        ),
        uploadImageCompressor: const _FakeUploadImageCompressor(
          compressedPath: '/tmp/id-front-compressed.jpg',
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationUpload,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'productId': '123',
          'selectedIdentityValue': 'PRC',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo Album'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(apiService.uploadedFilePath, '/tmp/id-front-compressed.jpg');
    expect(apiService.uploadedBody, <String, dynamic>{
      'outcrop': '11',
      'blessedness': '1',
      'impotencies': 'PRC',
    });
  });

  testWidgets('identity upload page uploads photographed image', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
    );
    Get.put<ApiService>(apiService, permanent: true);

    await tester.pumpWidget(
      _buildTestApp(
        uploadImagePicker: _FakeUploadImagePicker(
          cameraFilePath: '/tmp/id-camera.png',
        ),
        uploadImageCompressor: const _FakeUploadImageCompressor(
          compressedPath: '/tmp/id-camera-compressed.jpg',
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationUpload,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'productId': '123',
          'selectedIdentityValue': 'PRC',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photograph'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(apiService.uploadedFilePath, '/tmp/id-camera-compressed.jpg');
    expect(apiService.uploadedBody, <String, dynamic>{
      'outcrop': '11',
      'blessedness': '2',
      'impotencies': 'PRC',
    });
  });

  testWidgets('identity upload page opens success page with recognized info', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
      uploadResponseData: const <String, dynamic>{
        'governmental': 'SIMBAJON JR ROLANDO MAESTRE',
        'underspin': '0111-9695505-5',
        'studiednesses': '1995/05/31',
        'sidearms': '',
      },
    );
    Get.put<ApiService>(apiService, permanent: true);

    await tester.pumpWidget(
      _buildTestApp(
        uploadImagePicker: _FakeUploadImagePicker(
          galleryFilePath: '/tmp/id-front.png',
        ),
        uploadImageCompressor: const _FakeUploadImageCompressor(
          compressedPath: '/tmp/id-front-compressed.jpg',
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationUpload,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'selectedIdentityValue': 'PRC',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo Album'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(CertificationUploadSuccessPage), findsOneWidget);
    expect(find.text('SIMBAJON JR ROLANDO MAESTRE'), findsOneWidget);
    expect(find.text('0111-9695505-5'), findsOneWidget);
    expect(find.text('1995/05/31'), findsOneWidget);
  });

  testWidgets('identity upload success page submits recognized info', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
    );
    Get.put<ApiService>(apiService, permanent: true);

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationUploadSuccess,
      arguments: <String, dynamic>{
        'identityType': 'PRC',
        'result': <String, dynamic>{
          'governmental': 'SIMBAJON JR ROLANDO MAESTRE',
          'underspin': '0111-9695505-5',
          'studiednesses': '1995/05/31',
          'sidearms': '',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiService.savedIdentityBody, <String, dynamic>{
      'studiednesses': '31-05-1995',
      'underspin': '0111-9695505-5',
      'governmental': 'SIMBAJON JR ROLANDO MAESTRE',
      'outcrop': '11',
      'impotencies': 'PRC',
    });
  });

  testWidgets('identity verification page shows network exception message only', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        fetchError: const NetworkException('Only message'),
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationStep,
      arguments: <String, dynamic>{
        'routeKey': 'public',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Identity verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Only message'), findsOneWidget);
    expect(
      find.text('NetworkException(code: null, message: Only message)'),
      findsNothing,
    );
  });
}

Widget _buildTestApp({
  CertificationUploadImagePicker? uploadImagePicker,
  CertificationUploadImageCompressor? uploadImageCompressor,
}) {
  return GetMaterialApp(
    builder: (context, child) {
      ScreenAdapter.init(context);
      final easyLoadingBuilder = EasyLoading.init();
      return easyLoadingBuilder(context, child);
    },
    home: const Scaffold(body: SizedBox.shrink()),
    getPages: <GetPage<dynamic>>[
      GetPage(
        name: AppRoutes.certificationStep,
        page: () => const CertificationStepPage(),
      ),
      GetPage(
        name: AppRoutes.certificationUpload,
        page: () => CertificationUploadPage(
          imagePicker: uploadImagePicker,
          imageCompressor: uploadImageCompressor,
        ),
      ),
      GetPage(
        name: AppRoutes.certificationUploadSuccess,
        page: () => const CertificationUploadSuccessPage(),
      ),
    ],
  );
}

class _FakeUploadImagePicker implements CertificationUploadImagePicker {
  const _FakeUploadImagePicker({this.cameraFilePath, this.galleryFilePath});

  final String? cameraFilePath;
  final String? galleryFilePath;

  @override
  Future<String?> pickFromCamera() async => cameraFilePath;

  @override
  Future<String?> pickFromGallery() async => galleryFilePath;
}

class _FakeUploadImageCompressor implements CertificationUploadImageCompressor {
  const _FakeUploadImageCompressor({required this.compressedPath});

  final String compressedPath;

  @override
  Future<String?> compressToLimit(String filePath) async => compressedPath;
}

class _FakeApiService extends ApiService {
  _FakeApiService({
    required this.expectedProductId,
    required Map<String, dynamic> responseData,
    this.uploadResponseData = const <String, dynamic>{},
    this.fetchError,
  }) : _responseData = responseData,
       super(
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

  final Map<String, dynamic> _responseData;
  final Map<String, dynamic> uploadResponseData;
  final String expectedProductId;
  final Object? fetchError;
  String? uploadedFilePath;
  Map<String, dynamic> uploadedBody = const <String, dynamic>{};
  Map<String, dynamic> savedIdentityBody = const <String, dynamic>{};

  @override
  Future<NetworkResponse> fetchIdentityInfo(Map<String, dynamic> params) async {
    expect(params['cohabiter'], expectedProductId);
    if (fetchError != null) {
      throw fetchError!;
    }
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(_responseData),
      raw: _responseData,
    );
  }

  @override
  Future<NetworkResponse> uploadIdentityOrFace({
    required Map<String, dynamic> body,
    String? filePath,
  }) async {
    uploadedBody = body;
    uploadedFilePath = filePath;
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(uploadResponseData),
      raw: uploadResponseData,
    );
  }

  @override
  Future<NetworkResponse> saveIdentityInfo(Map<String, dynamic> body) async {
    savedIdentityBody = body;
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(const <String, dynamic>{}),
      raw: const <String, dynamic>{},
    );
  }
}
