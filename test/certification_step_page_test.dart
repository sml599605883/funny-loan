import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/core/native/native_bridge.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_face_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_personal_info_page.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();
  const trustDecisionChannel = MethodChannel('funny_loan/native_bridge');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(trustDecisionChannel, (call) async {
          if (call.method != 'showTrustDecisionLiveness') {
            return null;
          }
          return <String, dynamic>{
            'success': true,
            'code': 0,
            'message': 'ok',
            'image': 'SGVsbG8=',
            'liveness_id': 'live-1',
            'raw': <String, dynamic>{
              'sequenceId': 'face-seq',
              'image': 'SGVsbG8=',
              'liveness_id': 'live-1',
            },
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(trustDecisionChannel, null);
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

  testWidgets('face page renders independently', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{'nextStepTitle': 'Face verification'},
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CertificationFacePage), findsOneWidget);
    expect(find.text('Face verification'), findsOneWidget);
    expect(
      find.byKey(const Key('certification_face_demo_image')),
      findsOneWidget,
    );
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('face page submit triggers trust decision liveness', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        faceTokenResponseData: const <String, dynamic>{
          'grayly': 200,
          'unwarned': 'td-token',
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        facePageBuilder: () => CertificationFacePage(
          requestCameraPermission: () async => PermissionStatus.granted,
          showTrustDecisionLiveness: (unwarned) async =>
              const TrustDecisionLivenessResult(
                success: true,
                code: 0,
                message: 'ok',
                image: 'SGVsbG8=',
                sequenceId: 'face-seq',
                livenessId: 'live-1',
                raw: <String, dynamic>{
                  'sequenceId': 'face-seq',
                  'image': 'SGVsbG8=',
                  'liveness_id': 'live-1',
                },
              ),
          faceImageFilePathBuilder: (imageBase64) async => '/tmp/face.jpg',
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Face verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      Get.find<ApiService>() is _FakeApiService
          ? (Get.find<ApiService>() as _FakeApiService).uploadedBody
          : const <String, dynamic>{},
      <String, dynamic>{
        'outcrop': '10',
        'blessedness': '1',
        'impotencies': '',
        'shammying': 'live-1',
        'rapaciousness': 'td-token',
        'draggingly': '7',
        'workbook': '',
      },
    );
    expect(
      (Get.find<ApiService>() as _FakeApiService).uploadedFilePath,
      isNotEmpty,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'face page fetches product detail and dispatches personal next step after submit success',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          faceTokenResponseData: const <String, dynamic>{
            'grayly': 200,
            'unwarned': 'td-token',
          },
          productDetailResponseData: const <String, dynamic>{
            'accretes': <String, dynamic>{
              'isolines': '123',
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
        ),
        permanent: true,
      );

      await tester.pumpWidget(
        _buildTestApp(
          facePageBuilder: () => CertificationFacePage(
            requestCameraPermission: () async => PermissionStatus.granted,
            showTrustDecisionLiveness: (unwarned) async =>
                const TrustDecisionLivenessResult(
                  success: true,
                  code: 0,
                  message: 'ok',
                  image: 'SGVsbG8=',
                  sequenceId: 'face-seq',
                  livenessId: 'live-1',
                  raw: <String, dynamic>{
                    'sequenceId': 'face-seq',
                    'image': 'SGVsbG8=',
                    'liveness_id': 'live-1',
                  },
                ),
            faceImageFilePathBuilder: (imageBase64) async => '/tmp/face.jpg',
          ),
        ),
      );

      Get.toNamed<dynamic>(
        AppRoutes.certificationFace,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Face verification',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump();
      await tester.pumpAndSettle();

      final apiService = Get.find<ApiService>() as _FakeApiService;
      expect(apiService.fetchedProductDetailBody, <String, dynamic>{
        'cohabiter': '123',
      });
      expect(find.byType(CertificationPersonalInfoPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('face page shows camera permission dialog when denied', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
      ),
      permanent: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        facePageBuilder: () => CertificationFacePage(
          requestCameraPermission: () async => PermissionStatus.denied,
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Face verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Camera permission required'), findsOneWidget);
    expect(
      find.text('Please enable camera access in Settings to continue.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('face page opens settings when permission dialog confirms', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
      ),
      permanent: true,
    );
    var openedSettings = false;

    await tester.pumpWidget(
      _buildTestApp(
        facePageBuilder: () => CertificationFacePage(
          requestCameraPermission: () async => PermissionStatus.denied,
          openAppSettingsPage: () async {
            openedSettings = true;
            return true;
          },
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Face verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(openedSettings, isTrue);
  });

  testWidgets('face page shows reupload dialog when grayly is 400', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        faceTokenResponseData: const <String, dynamic>{'grayly': 400},
      ),
      permanent: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        facePageBuilder: () => CertificationFacePage(
          requestCameraPermission: () async => PermissionStatus.granted,
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Face verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Please re-upload your ID photo'), findsOneWidget);
    expect(
      find.text(
        'Your ID photo needs to be uploaded again before face verification.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsWidgets);
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('face page shows cithrens toast when grayly is 500', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        faceTokenResponseData: const <String, dynamic>{
          'grayly': 500,
          'cithrens': 'face token error',
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(
      _buildTestApp(
        facePageBuilder: () => CertificationFacePage(
          requestCameraPermission: () async => PermissionStatus.granted,
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Face verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('face token error'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'face page reads hint banner text from product detail scabiosa cache',
    (WidgetTester tester) async {
      AppDataStore.setCache(
        AppDataStore.productDetailScabiosaCacheKey,
        <String, String>{'extricating': 'cached face top'},
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationFace,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{'nextStepTitle': 'Face verification'},
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('cached face top'), findsOneWidget);
      expect(
        find.text('Please keep your face clear and centered in the frame.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'identity upload page reads hint banner text from product detail scabiosa cache',
    (WidgetTester tester) async {
      AppDataStore.setCache(
        AppDataStore.productDetailScabiosaCacheKey,
        <String, String>{'beveling': 'cached upload top'},
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationUpload,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Identity verification',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('cached upload top'), findsOneWidget);
      expect(
        find.text('Snap your valid ID Clear photo, quick check'),
        findsNothing,
      );
    },
  );

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
    expect(find.text('31-05-1995'), findsOneWidget);
  });

  testWidgets('identity upload success page submits recognized info', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
    );
    Get.put<ApiService>(apiService, permanent: true);

    await tester.pumpWidget(
      _buildTestApp(
        successPageBuilder: () => CertificationUploadSuccessPage(
          productDetailFlowRunner: (productId) async => <String, dynamic>{
            'handled': true,
          },
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationUploadSuccess,
      arguments: <String, dynamic>{
        'identityType': 'PRC',
        'productId': '123',
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

  testWidgets(
    'identity upload success page fetches product detail and dispatches Hoarily next step after submit success',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
      );
      Get.put<ApiService>(apiService, permanent: true);
      String? fetchedProductId;

      await tester.pumpWidget(
        _buildTestApp(
          successPageBuilder: () => CertificationUploadSuccessPage(
            productDetailFlowRunner: (productId) async {
              fetchedProductId = productId;
            },
          ),
        ),
      );

      Get.toNamed<dynamic>(
        AppRoutes.certificationUploadSuccess,
        arguments: <String, dynamic>{
          'identityType': 'PRC',
          'productId': '123',
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

      expect(fetchedProductId, '123');
    },
  );

  testWidgets(
    'identity upload success page allows editing name and id number only',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
      );
      Get.put<ApiService>(apiService, permanent: true);

      await tester.pumpWidget(
        _buildTestApp(
          successPageBuilder: () => CertificationUploadSuccessPage(
            birthDatePicker: (context, initialDate) async => null,
          ),
        ),
      );

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

      await tester.enterText(
        find.byKey(const Key('certification_success_full_name_input')),
        'UPDATED NAME',
      );
      await tester.enterText(
        find.byKey(const Key('certification_success_id_number_input')),
        'NEW-ID-123',
      );
      await tester.tap(
        find.byKey(const Key('certification_success_birth_date')),
      );
      await tester.pumpAndSettle();

      expect(find.text('31-05-1995'), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(apiService.savedIdentityBody, <String, dynamic>{
        'studiednesses': '31-05-1995',
        'underspin': 'NEW-ID-123',
        'governmental': 'UPDATED NAME',
        'outcrop': '11',
        'impotencies': 'PRC',
      });
    },
  );

  testWidgets(
    'identity upload success page updates birth date from picker with dd-MM-yyyy format',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
      );
      Get.put<ApiService>(apiService, permanent: true);

      await tester.pumpWidget(
        _buildTestApp(
          successPageBuilder: () => CertificationUploadSuccessPage(
            birthDatePicker: (context, initialDate) async => '09-06-1998',
          ),
        ),
      );

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

      expect(find.text('31-05-1995'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('certification_success_birth_date')),
      );
      await tester.pumpAndSettle();

      expect(find.text('09-06-1998'), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(apiService.savedIdentityBody, <String, dynamic>{
        'studiednesses': '09-06-1998',
        'underspin': '0111-9695505-5',
        'governmental': 'SIMBAJON JR ROLANDO MAESTRE',
        'outcrop': '11',
        'impotencies': 'PRC',
      });
    },
  );

  testWidgets(
    'identity upload success page birth date picker uses dd-MM-yyyy order',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
        ),
        permanent: true,
      );

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

      await tester.tap(
        find.byKey(const Key('certification_success_birth_date')),
      );
      await tester.pumpAndSettle();

      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.dateOrder, DatePickerDateOrder.dmy);
    },
  );

  testWidgets(
    'identity upload success page reads hint banner text from product detail scabiosa cache',
    (WidgetTester tester) async {
      AppDataStore.setCache(
        AppDataStore.productDetailScabiosaCacheKey,
        <String, String>{'vicomtes': 'cached success top'},
      );

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

      expect(find.text('cached success top'), findsOneWidget);
      expect(
        find.text(
          'A clear ID photo is the key to lightning-fast approval. Please upload ID front.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets('personal info page renders independently', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        userInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Gender',
                'tissual': 'Please select gender',
                'unplait': 'orbs',
                'dulses': 'Ataractics',
                'dominances': 0,
                'scabiosa': <Map<String, dynamic>>[
                  <String, dynamic>{'governmental': 'Female', 'outcrop': 2},
                  <String, dynamic>{'governmental': 'Male', 'outcrop': 1},
                ],
                'disrelished': 'Female',
              },
              <String, dynamic>{
                'hazinesses': 'Home Phone Number',
                'tissual': 'Please enter',
                'unplait': 'fragging',
                'dulses': 'Craniosacral',
                'dominances': 1,
                'scabiosa': <dynamic>[],
                'disrelished': '09998887777',
              },
              <String, dynamic>{
                'hazinesses': 'Residential Address',
                'tissual': 'Please select address',
                'unplait': 'kneepieces',
                'dulses': 'RestroomInefficacies',
                'dominances': 0,
                'scabiosa': <dynamic>[],
                'disrelished': 'Region I-Pangasinan-Alcala',
              },
              <String, dynamic>{
                'hazinesses': 'FaceBook Account(Optional)',
                'tissual': 'Please enter',
                'unplait': 'varve',
                'dulses': 'Craniosacral',
                'dominances': 0,
                'scabiosa': <dynamic>[],
                'disrelished': 'Jane Doe',
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationPersonalInfo,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Personal information',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CertificationPersonalInfoPage), findsOneWidget);
    expect(find.text('Personal information'), findsOneWidget);
    expect(
      find.byKey(const Key('certification_personal_info_orbs_selector')),
      findsOneWidget,
    );
    expect(find.text('Female'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('certification_personal_info_fragging_input')),
          )
          .controller
          ?.text,
      '09998887777',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('certification_personal_info_varve_input')),
          )
          .controller
          ?.text,
      'Jane Doe',
    );
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('personal info page submits edited values', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
      userInfoResponseData: const <String, dynamic>{
        'rekeys': <String, dynamic>{
          'tingling': <Map<String, dynamic>>[
            <String, dynamic>{
              'hazinesses': 'Gender',
              'tissual': 'Please select gender',
              'unplait': 'orbs',
              'dulses': 'Ataractics',
              'dominances': 0,
              'scabiosa': <Map<String, dynamic>>[
                <String, dynamic>{'governmental': 'Female', 'outcrop': 2},
                <String, dynamic>{'governmental': 'Male', 'outcrop': 1},
              ],
              'disrelished': 'Female',
            },
            <String, dynamic>{
              'hazinesses': 'Home Phone Number',
              'tissual': 'Please enter',
              'unplait': 'fragging',
              'dulses': 'Craniosacral',
              'dominances': 1,
              'scabiosa': <dynamic>[],
              'disrelished': '09998887777',
            },
            <String, dynamic>{
              'hazinesses': 'Residential Address',
              'tissual': 'Please select address',
              'unplait': 'kneepieces',
              'dulses': 'RestroomInefficacies',
              'dominances': 0,
              'scabiosa': <dynamic>[],
              'disrelished': 'Region I-Pangasinan-Alcala',
            },
            <String, dynamic>{
              'hazinesses': 'FaceBook Account(Optional)',
              'tissual': 'Please enter',
              'unplait': 'varve',
              'dulses': 'Craniosacral',
              'dominances': 0,
              'scabiosa': <dynamic>[],
              'disrelished': 'Jane Doe',
            },
          ],
        },
      },
    );
    Get.put<ApiService>(apiService, permanent: true);
    String? fetchedProductId;

    await tester.pumpWidget(
      _buildTestApp(
        personalInfoPageBuilder: () => CertificationPersonalInfoPage(
          productDetailFlowRunner: (productId) async {
            fetchedProductId = productId;
          },
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationPersonalInfo,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Personal information',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('certification_personal_info_orbs_selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('certification_personal_info_kneepieces_selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Province B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('City B1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('District B1A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('certification_personal_info_fragging_input')),
      '09171234567',
    );
    await tester.enterText(
      find.byKey(const Key('certification_personal_info_varve_input')),
      'mary.jane.fb',
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(apiService.savedUserInfoBody, <String, dynamic>{
      'cohabiter': '123',
      'orbs': '1',
      'fragging': '09171234567',
      'kneepieces': 'Province B-City B1-District B1A',
      'varve': 'mary.jane.fb',
    });
    expect(fetchedProductId, '123');
  });

  testWidgets(
    'address sheet advances step by step and commits on third-level done',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          userInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Residential Address',
                  'tissual': 'Please select address',
                  'unplait': 'kneepieces',
                  'dulses': 'RestroomInefficacies',
                  'dominances': 0,
                  'scabiosa': <dynamic>[],
                  'disrelished': 'Province A-City A1-District A1A',
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationPersonalInfo,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Personal information',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Province A-City A1-District A1A'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const Key('certification_personal_info_kneepieces_selector'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Province A').last, findsOneWidget);

      await tester.tap(find.text('Province B'));
      await tester.pumpAndSettle();
      expect(find.text('Province A-City A1-District A1A'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Province B'), findsWidgets);
      expect(find.text('City B1'), findsWidgets);
      await tester.tap(find.text('City B1').last);
      await tester.pumpAndSettle();
      expect(find.text('Province A-City A1-District A1A'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('District B1A').last);
      await tester.pumpAndSettle();
      expect(find.text('Province A-City A1-District A1A'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Province B-City B1-District B1A'), findsOneWidget);
    },
  );

  testWidgets('address sheet cancel keeps previous address value', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        userInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Residential Address',
                'tissual': 'Please select address',
                'unplait': 'kneepieces',
                'dulses': 'RestroomInefficacies',
                'dominances': 0,
                'scabiosa': <dynamic>[],
                'disrelished': 'Province A-City A1-District A1A',
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationPersonalInfo,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Personal information',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('certification_personal_info_kneepieces_selector')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Province B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('City B1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('District B1A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Province A-City A1-District A1A'), findsOneWidget);
    expect(find.text('Province B-City B1-District B1A'), findsNothing);
  });

  testWidgets(
    'address sheet title tap clears deeper selections and restarts there',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          userInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Residential Address',
                  'tissual': 'Please select address',
                  'unplait': 'kneepieces',
                  'dulses': 'RestroomInefficacies',
                  'dominances': 0,
                  'scabiosa': <dynamic>[],
                  'disrelished': 'Province A-City A1-District A1A',
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationPersonalInfo,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Personal information',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('certification_personal_info_kneepieces_selector'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Province B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('City B1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('District B1A').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('personal_address_segment_province')),
      );
      await tester.pumpAndSettle();
      expect(find.text('City B1'), findsWidgets);
      expect(find.text('District B1A'), findsNothing);

      await tester.tap(
        find.byKey(const Key('personal_address_segment_region')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Province A'), findsOneWidget);
      expect(find.text('Province B'), findsOneWidget);
      expect(find.text('City B1'), findsNothing);
    },
  );

  testWidgets(
    'personal info page prefetches and reuses cached address options',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        userInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Residential Address',
                'tissual': 'Please select address',
                'unplait': 'kneepieces',
                'dulses': 'RestroomInefficacies',
                'dominances': 0,
                'scabiosa': <dynamic>[],
                'disrelished': 'Province A-City A1-District A1A',
              },
            ],
          },
        },
      );
      Get.put<ApiService>(apiService, permanent: true);

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationPersonalInfo,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Personal information',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(apiService.fetchAddressOptionsCallCount, 1);

      await tester.tap(
        find.byKey(
          const Key('certification_personal_info_kneepieces_selector'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('certification_personal_info_kneepieces_selector'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(apiService.fetchAddressOptionsCallCount, 1);
    },
  );

  testWidgets('personal info enum sheet stays within small screen height', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        userInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Bank',
                'tissual': 'Please select bank',
                'unplait': 'orbs',
                'dulses': 'Ataractics',
                'dominances': 0,
                'scabiosa': <Map<String, dynamic>>[
                  <String, dynamic>{'governmental': 'BDO', 'outcrop': 1},
                  <String, dynamic>{'governmental': 'MAYBANK', 'outcrop': 2},
                  <String, dynamic>{'governmental': 'Union Bank', 'outcrop': 3},
                  <String, dynamic>{'governmental': 'BPI', 'outcrop': 4},
                  <String, dynamic>{'governmental': 'Metrobank', 'outcrop': 5},
                  <String, dynamic>{'governmental': 'PNB', 'outcrop': 6},
                ],
                'disrelished': '1',
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationPersonalInfo,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Personal information',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('certification_personal_info_orbs_selector')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ListView).last).height,
      lessThanOrEqualTo(326.h),
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('personal info enum sheet hides empty option logo', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        userInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Bank',
                'tissual': 'Please select bank',
                'unplait': 'orbs',
                'dulses': 'Ataractics',
                'dominances': 0,
                'scabiosa': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'governmental': 'GCash e-wallet',
                    'outcrop': 6,
                    'euchromatic': 'https://example.com/gcash.png',
                  },
                  <String, dynamic>{
                    'governmental': 'AllBank Inc.',
                    'outcrop': 'ABP',
                    'euchromatic': '',
                  },
                ],
                'disrelished': '6',
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationPersonalInfo,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Personal information',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('certification_personal_info_orbs_selector')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                'https://example.com/gcash.png';
      }),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('AllBank Inc.')).dx,
      lessThan(tester.getTopLeft(find.text('GCash e-wallet').last).dx),
    );
  });

  testWidgets(
    'identity verification page shows network exception message only',
    (WidgetTester tester) async {
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
    },
  );
}

Widget _buildTestApp({
  CertificationUploadImagePicker? uploadImagePicker,
  CertificationUploadImageCompressor? uploadImageCompressor,
  Widget Function()? successPageBuilder,
  Widget Function()? facePageBuilder,
  Widget Function()? personalInfoPageBuilder,
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
        name: AppRoutes.certificationFace,
        page: facePageBuilder ?? () => const CertificationFacePage(),
      ),
      GetPage(
        name: AppRoutes.certificationUploadSuccess,
        page:
            successPageBuilder ?? () => const CertificationUploadSuccessPage(),
      ),
      GetPage(
        name: AppRoutes.certificationPersonalInfo,
        page:
            personalInfoPageBuilder ??
            () => const CertificationPersonalInfoPage(),
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
    this.faceTokenResponseData = const <String, dynamic>{},
    this.productDetailResponseData = const <String, dynamic>{},
    this.userInfoResponseData = const <String, dynamic>{},
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
  final Map<String, dynamic> faceTokenResponseData;
  final Map<String, dynamic> productDetailResponseData;
  final Map<String, dynamic> userInfoResponseData;
  final String expectedProductId;
  final Object? fetchError;
  int fetchAddressOptionsCallCount = 0;
  String? uploadedFilePath;
  Map<String, dynamic> uploadedBody = const <String, dynamic>{};
  Map<String, dynamic> savedIdentityBody = const <String, dynamic>{};
  Map<String, dynamic> savedUserInfoBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedFaceTokenBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedProductDetailBody = const <String, dynamic>{};

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
  Future<NetworkResponse> fetchFaceToken(Map<String, dynamic> body) async {
    fetchedFaceTokenBody = body;
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(faceTokenResponseData),
      raw: faceTokenResponseData,
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
  Future<NetworkResponse> fetchUserInfo(Map<String, dynamic> body) async {
    expect(body['cohabiter'], expectedProductId);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(userInfoResponseData),
      raw: userInfoResponseData,
    );
  }

  @override
  Future<NetworkResponse> fetchAddressOptions() async {
    fetchAddressOptionsCallCount++;
    const responseData = <String, dynamic>{
      'keelboat': <Map<String, dynamic>>[
        <String, dynamic>{
          'governmental': 'Province A',
          'keelboat': <Map<String, dynamic>>[
            <String, dynamic>{
              'governmental': 'City A1',
              'keelboat': <Map<String, dynamic>>[
                <String, dynamic>{'governmental': 'District A1A'},
              ],
            },
          ],
        },
        <String, dynamic>{
          'governmental': 'Province B',
          'keelboat': <Map<String, dynamic>>[
            <String, dynamic>{
              'governmental': 'City B1',
              'keelboat': <Map<String, dynamic>>[
                <String, dynamic>{'governmental': 'District B1A'},
              ],
            },
          ],
        },
      ],
    };
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(responseData),
      raw: responseData,
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

  @override
  Future<NetworkResponse> saveUserInfo(Map<String, dynamic> body) async {
    savedUserInfoBody = body;
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(const <String, dynamic>{}),
      raw: const <String, dynamic>{},
    );
  }
}
