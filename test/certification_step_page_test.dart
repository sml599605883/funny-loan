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
import 'package:funny_loan/app/modules/certification_step/views/certification_bind_card_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_face_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_personal_info_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_step_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_upload_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_upload_success_page.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_work_info_page.dart';
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

  testWidgets(
    'face page fetches product detail and dispatches work info next step after submit success',
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
            'gewurztraminers': 200,
            'reallot': '',
            'accretes': <String, dynamic>{
              'isolines': '123',
              'disprovable': 'Cash Loan',
              'rejectee': 'ORD-1',
            },
            'oocytes': <dynamic>[],
            'tetragrammaton': <String, dynamic>{
              'sidearms': 'work',
              'hazinesses': 'Work Information',
              'rutherfordiums': 'job',
              'outcrop': 0,
            },
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
      expect(find.byType(CertificationWorkInfoPage), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Image) {
            return false;
          }
          final imageProvider = widget.image;
          return imageProvider is AssetImage &&
              imageProvider.assetName ==
                  'assets/certification/certification_personal_progress_step2.png';
        }),
        findsOneWidget,
      );
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
    'identity upload success page does not refocus previous input after birth date sheet closes',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
        ),
        permanent: true,
      );

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

      final nameField = find.byKey(
        const Key('certification_success_full_name_input'),
      );
      await tester.tap(nameField);
      await tester.pump();

      final successEditable = tester.widget<EditableText>(
        find.descendant(of: nameField, matching: find.byType(EditableText)),
      );
      expect(successEditable.focusNode.hasFocus, isTrue);

      await tester.tap(
        find.byKey(const Key('certification_success_birth_date')),
      );
      await tester.pumpAndSettle();

      expect(successEditable.focusNode.hasFocus, isFalse);
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

  testWidgets('work info page submits edited values', (
    WidgetTester tester,
  ) async {
    final apiService = _FakeApiService(
      expectedProductId: '123',
      responseData: const <String, dynamic>{},
      userInfoResponseData: const <String, dynamic>{
        'rekeys': <String, dynamic>{
          'tingling': <Map<String, dynamic>>[
            <String, dynamic>{
              'hazinesses': 'Company Name',
              'tissual': 'Please enter',
              'unplait': 'interrogators',
              'dulses': 'Craniosacral',
              'dominances': 0,
              'scabiosa': <dynamic>[],
              'disrelished': 'Old Company',
            },
            <String, dynamic>{
              'hazinesses': 'City You Work',
              'tissual': 'Please select city',
              'unplait': 'picklocks',
              'dulses': 'RestroomInefficacies',
              'dominances': 0,
              'scabiosa': <dynamic>[],
              'disrelished': 'Province A-City A1-District A1A',
            },
            <String, dynamic>{
              'hazinesses': 'Type of Work',
              'tissual': 'Please select type',
              'unplait': 'placets',
              'dulses': 'Ataractics',
              'dominances': 0,
              'scabiosa': <Map<String, dynamic>>[
                <String, dynamic>{
                  'governmental': 'Office Worker',
                  'outcrop': 1,
                },
                <String, dynamic>{'governmental': 'Driver', 'outcrop': 2},
              ],
              'disrelished': '1',
            },
          ],
        },
      },
    );
    Get.put<ApiService>(apiService, permanent: true);
    String? fetchedProductId;

    await tester.pumpWidget(
      _buildTestApp(
        workInfoPageBuilder: () => CertificationWorkInfoPage(
          productDetailFlowRunner: (productId) async {
            fetchedProductId = productId;
          },
        ),
      ),
    );

    Get.toNamed<dynamic>(
      AppRoutes.certificationWorkInfo,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Work Information',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('certification_work_info_interrogators_input')),
      'New Company',
    );
    await tester.tap(
      find.byKey(const Key('certification_work_info_picklocks_selector')),
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
    await tester.tap(
      find.byKey(const Key('certification_work_info_placets_selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(apiService.savedWorkInfoBody, <String, dynamic>{
      'cohabiter': '123',
      'interrogators': 'New Company',
      'picklocks': 'Province B-City B1-District B1A',
      'placets': '2',
    });
    expect(fetchedProductId, '123');
  });

  testWidgets(
    'personal info page does not refocus previous input after enum sheet closes',
    (WidgetTester tester) async {
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

      final phoneField = find.byKey(
        const Key('certification_personal_info_fragging_input'),
      );
      await tester.tap(phoneField);
      await tester.pump();

      final personalEditable = tester.widget<EditableText>(
        find.descendant(of: phoneField, matching: find.byType(EditableText)),
      );
      expect(personalEditable.focusNode.hasFocus, isTrue);

      await tester.tap(
        find.byKey(const Key('certification_personal_info_orbs_selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(personalEditable.focusNode.hasFocus, isFalse);
    },
  );

  testWidgets(
    'work info page does not refocus previous input after enum sheet closes',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          userInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Company Name',
                  'tissual': 'Please enter',
                  'unplait': 'interrogators',
                  'dulses': 'Craniosacral',
                  'dominances': 0,
                  'scabiosa': <dynamic>[],
                  'disrelished': 'Old Company',
                },
                <String, dynamic>{
                  'hazinesses': 'Type of Work',
                  'tissual': 'Please select type',
                  'unplait': 'placets',
                  'dulses': 'Ataractics',
                  'dominances': 0,
                  'scabiosa': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'governmental': 'Office Worker',
                      'outcrop': 1,
                    },
                    <String, dynamic>{'governmental': 'Driver', 'outcrop': 2},
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
        AppRoutes.certificationWorkInfo,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Work Information',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final companyField = find.byKey(
        const Key('certification_work_info_interrogators_input'),
      );
      await tester.tap(companyField);
      await tester.pump();

      final workEditable = tester.widget<EditableText>(
        find.descendant(of: companyField, matching: find.byType(EditableText)),
      );
      expect(workEditable.focusNode.hasFocus, isTrue);

      await tester.tap(
        find.byKey(const Key('certification_work_info_placets_selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(workEditable.focusNode.hasFocus, isFalse);
    },
  );

  testWidgets(
    'work info salary day selector shows pipe text and submits second-level value',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        userInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Company Name',
                'tissual': 'Please enter',
                'unplait': 'interrogators',
                'dulses': 'Craniosacral',
                'dominances': 0,
                'scabiosa': <dynamic>[],
                'disrelished': 'Old Company',
              },
              <String, dynamic>{
                'hazinesses': 'Salary Day',
                'tissual': 'Please select salary day',
                'unplait': 'dines',
                'dulses': 'Ataractics',
                'dominances': 0,
                'scabiosa': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'governmental': '1st Half',
                    'outcrop': 'half_1',
                    'keelboat': <Map<String, dynamic>>[
                      <String, dynamic>{'governmental': '5th', 'outcrop': '5'},
                      <String, dynamic>{
                        'governmental': '10th',
                        'outcrop': '10',
                      },
                    ],
                  },
                  <String, dynamic>{
                    'governmental': '2nd Half',
                    'outcrop': 'half_2',
                    'keelboat': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': '20th',
                        'outcrop': '20',
                      },
                      <String, dynamic>{
                        'governmental': '25th',
                        'outcrop': '25',
                      },
                    ],
                  },
                ],
                'disrelished': '',
              },
            ],
          },
        },
      );
      Get.put<ApiService>(apiService, permanent: true);

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationWorkInfo,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{
            'nextStepTitle': 'Work Information',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('certification_work_info_dines_selector')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('2nd Half'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('25th').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('2nd Half|25th'), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(apiService.savedWorkInfoBody, <String, dynamic>{
        'cohabiter': '123',
        'interrogators': 'Old Company',
        'dines': '25',
      });
    },
  );

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

  testWidgets('bind card page renders fetched bank options', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        bindCardInfoResponseData: const <String, dynamic>{
          'unchains':
              'Please select the most convenient way for you to withdraw.',
          'omitted':
              'Double-check your account details—once submitted, funds will go here!',
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'E-wallet',
                'outcrop': 1,
                'tingling': <Map<String, dynamic>>[],
              },
              <String, dynamic>{
                'hazinesses': 'Bank',
                'outcrop': 2,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient bank',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient bank',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'Banco de Oro',
                        'outcrop': 'BDO',
                      },
                      <String, dynamic>{
                        'governmental': 'Union Bank',
                        'outcrop': 'UBP',
                      },
                    ],
                    'disrelished': 'UBP',
                    'triadisms': 'Union Bank',
                  },
                  <String, dynamic>{
                    'hazinesses': 'First Name',
                    'unplait': 'firstName',
                    'tissual': 'First Name',
                    'dulses': 'txt',
                    'disrelished': 'John',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Middle Name',
                    'unplait': 'middleName',
                    'tissual': 'Middle Name',
                    'dulses': 'txt',
                    'centupling': 1,
                    'disrelished': '',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Last Name',
                    'unplait': 'lastName',
                    'tissual': 'Last Name',
                    'dulses': 'txt',
                    'disrelished': 'Doe',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Bank Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your bank account',
                    'dulses': 'txt',
                    'disrelished': '',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Repeat Bank Account',
                    'unplait': 'confirmCardNo',
                    'tissual': 'Ensure the account number is correct',
                    'dulses': 'txt',
                    'disrelished': '',
                  },
                ],
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationBindCard,
      arguments: <String, dynamic>{
        'routeKey': 'bank',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Informasi bank',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Informasi bank'), findsOneWidget);
    expect(
      find.byKey(const Key('certification_bind_card_channelCode_selector')),
      findsOneWidget,
    );
    expect(find.text('Union Bank'), findsOneWidget);
    expect(find.text('Bank Account'), findsOneWidget);
    expect(find.text('Repeat Bank Account'), findsOneWidget);
    expect(
      find.byKey(const Key('certification_bind_card_progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('certification_bind_card_firstName_input')),
      findsOneWidget,
    );
  });

  testWidgets(
    'bind card page submits selected bank account info and refreshes product detail',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        bindCardInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Bank',
                'outcrop': 2,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient bank',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient bank',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'Banco de Oro',
                        'outcrop': 'BDO',
                      },
                      <String, dynamic>{
                        'governmental': 'Union Bank',
                        'outcrop': 'UBP',
                      },
                    ],
                    'disrelished': 'UBP',
                    'triadisms': 'Union Bank',
                  },
                  <String, dynamic>{
                    'hazinesses': 'First Name',
                    'unplait': 'firstName',
                    'tissual': 'First Name',
                    'dulses': 'txt',
                    'disrelished': 'John',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Middle Name',
                    'unplait': 'middleName',
                    'tissual': 'Middle Name',
                    'dulses': 'txt',
                    'centupling': 1,
                    'disrelished': '',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Last Name',
                    'unplait': 'lastName',
                    'tissual': 'Last Name',
                    'dulses': 'txt',
                    'disrelished': 'Doe',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Bank Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your bank account',
                    'dulses': 'txt',
                    'disrelished': '',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Repeat Bank Account',
                    'unplait': 'confirmCardNo',
                    'tissual': 'Ensure the account number is correct',
                    'dulses': 'txt',
                    'disrelished': '',
                  },
                ],
              },
            ],
          },
        },
      );
      Get.put<ApiService>(apiService, permanent: true);
      String? fetchedProductId;

      await tester.pumpWidget(
        _buildTestApp(
          bindCardPageBuilder: () => CertificationBindCardPage(
            productDetailFlowRunner: (productId) async {
              fetchedProductId = productId;
            },
          ),
        ),
      );

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('certification_bind_card_cardNo_input')),
        '1234567890',
      );
      await tester.enterText(
        find.byKey(const Key('certification_bind_card_confirmCardNo_input')),
        '1234567890',
      );
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(apiService.submittedBindCardBody, <String, dynamic>{
        'cohabiter': '123',
        'impotencies': 2,
        'pinder': 'UBP',
        'gowans': 'John',
        'sunk': '',
        'bookstores': 'Doe',
        'hoppings': '1234567890',
        'copromoter': '1234567890',
      });
      expect(fetchedProductId, '123');
    },
  );

  testWidgets(
    'bind card page changes order bank card after change-account submit',
    (WidgetTester tester) async {
      final apiService = _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        bindCardSubmitResponseData: const <String, dynamic>{
          'triaged': 'bind-9',
        },
        changeBankCardResponseData: const <String, dynamic>{
          'copybooks': 'https://example.test/change-card-result',
        },
        bindCardInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'Bank',
                'outcrop': 2,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient bank',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient bank',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'Union Bank',
                        'outcrop': 'UBP',
                      },
                    ],
                    'disrelished': 'UBP',
                    'triadisms': 'Union Bank',
                  },
                  <String, dynamic>{
                    'hazinesses': 'First Name',
                    'unplait': 'firstName',
                    'tissual': 'First Name',
                    'dulses': 'txt',
                    'disrelished': 'John',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Last Name',
                    'unplait': 'lastName',
                    'tissual': 'Last Name',
                    'dulses': 'txt',
                    'disrelished': 'Doe',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Bank Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your bank account',
                    'dulses': 'txt',
                    'disrelished': '',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Repeat Bank Account',
                    'unplait': 'confirmCardNo',
                    'tissual': 'Ensure the account number is correct',
                    'dulses': 'txt',
                    'disrelished': '',
                  },
                ],
              },
            ],
          },
        },
      );
      Get.put<ApiService>(apiService, permanent: true);
      String? fetchedProductId;
      Map<String, dynamic>? webViewArguments;

      await tester.pumpWidget(
        _buildTestApp(
          bindCardPageBuilder: () => CertificationBindCardPage(
            productDetailFlowRunner: (productId) async {
              fetchedProductId = productId;
            },
          ),
          webViewPageBuilder: () {
            final arguments = Get.arguments;
            webViewArguments = arguments is Map
                ? Map<String, dynamic>.from(arguments)
                : const <String, dynamic>{};
            return const Scaffold(body: Text('Change card result webview'));
          },
        ),
      );

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
            'orderNo': 'order-9',
            'ischange': true,
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('certification_bind_card_cardNo_input')),
        '1234567890',
      );
      await tester.enterText(
        find.byKey(const Key('certification_bind_card_confirmCardNo_input')),
        '1234567890',
      );
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(apiService.changedBankCardBody, <String, dynamic>{
        'nosh': 'order-9',
        'triaged': 'bind-9',
      });
      expect(find.text('Change card result webview'), findsOneWidget);
      expect(webViewArguments, <String, dynamic>{
        'url': 'https://example.test/change-card-result',
      });
      expect(fetchedProductId, isNull);
    },
  );

  testWidgets(
    'bind card page text input displays disrelished instead of triadisms',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          bindCardInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Bank',
                  'outcrop': 2,
                  'tingling': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'hazinesses': 'First Name',
                      'unplait': 'firstName',
                      'tissual': 'First Name',
                      'dulses': 'txt',
                      'disrelished': 'Shown Name',
                      'triadisms': 'Suggested Name',
                    },
                  ],
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Shown Name'), findsOneWidget);
      expect(find.text('Suggested Name'), findsNothing);
    },
  );

  testWidgets(
    'bind card page suggestion bubble close keeps it hidden until field changes away from empty and back',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          bindCardInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Bank',
                  'outcrop': 2,
                  'tingling': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'hazinesses': 'First Name',
                      'unplait': 'firstName',
                      'tissual': 'First Name',
                      'dulses': 'txt',
                      'disrelished': '',
                      'triadisms': 'John',
                    },
                  ],
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final firstNameFinder = find.byKey(
        const Key('certification_bind_card_firstName_input'),
      );
      final bubbleFinder = find.byKey(
        const Key('certification_bind_card_suggestion_bubble'),
      );

      await tester.tap(firstNameFinder);
      await tester.pumpAndSettle();
      expect(bubbleFinder, findsOneWidget);

      await tester.tap(
        find.byKey(const Key('certification_bind_card_suggestion_bubble_close')),
      );
      await tester.pumpAndSettle();
      expect(bubbleFinder, findsNothing);

      await tester.enterText(firstNameFinder, 'A');
      await tester.pumpAndSettle();
      expect(bubbleFinder, findsNothing);

      await tester.enterText(firstNameFinder, '');
      await tester.pumpAndSettle();
      expect(bubbleFinder, findsOneWidget);
    },
  );

  testWidgets(
    'bind card page suggestion bubble shows on focused empty text field and fills eligible empty fields',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          bindCardInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Bank',
                  'outcrop': 2,
                  'tingling': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'hazinesses': 'First Name',
                      'unplait': 'firstName',
                      'tissual': 'First Name',
                      'dulses': 'txt',
                      'disrelished': '',
                      'triadisms': 'John',
                    },
                    <String, dynamic>{
                      'hazinesses': 'Middle Name',
                      'unplait': 'middleName',
                      'tissual': 'Middle Name',
                      'dulses': 'txt',
                      'disrelished': '',
                      'triadisms': 'Michael',
                    },
                    <String, dynamic>{
                      'hazinesses': 'Last Name',
                      'unplait': 'lastName',
                      'tissual': 'Last Name',
                      'dulses': 'txt',
                      'disrelished': 'Doe',
                      'triadisms': 'Smith',
                    },
                  ],
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final firstNameFinder = find.byKey(
        const Key('certification_bind_card_firstName_input'),
      );
      final middleNameFinder = find.byKey(
        const Key('certification_bind_card_middleName_input'),
      );
      final lastNameFinder = find.byKey(
        const Key('certification_bind_card_lastName_input'),
      );

      await tester.tap(firstNameFinder);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('certification_bind_card_suggestion_bubble')),
        findsOneWidget,
      );
      expect(find.text('John'), findsOneWidget);
      expect(
        tester
            .getSize(
              find.byKey(
                const Key('certification_bind_card_suggestion_bubble'),
              ),
            )
            .width,
        lessThan(tester.getSize(firstNameFinder).width),
      );

      await tester.tap(
        find.byKey(const Key('certification_bind_card_suggestion_bubble')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        tester.widget<TextField>(firstNameFinder).controller?.text,
        'John',
      );
      expect(
        tester.widget<TextField>(middleNameFinder).controller?.text,
        'Michael',
      );
      expect(tester.widget<TextField>(lastNameFinder).controller?.text, 'Doe');
      expect(
        find.byKey(const Key('certification_bind_card_suggestion_bubble')),
        findsNothing,
      );
    },
  );

  testWidgets('bind card page switches field group when tapping method tabs', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        bindCardInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'E-wallet',
                'outcrop': 1,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient E-wallet',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient E-wallet',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'GCash e-wallet',
                        'outcrop': 'GCASH',
                      },
                    ],
                  },
                  <String, dynamic>{
                    'hazinesses': 'E-wallet Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your E-Wallet account',
                    'dulses': 'txt',
                  },
                ],
              },
              <String, dynamic>{
                'hazinesses': 'Bank',
                'outcrop': 2,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient bank',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient bank',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'Union Bank',
                        'outcrop': 'UBP',
                      },
                    ],
                  },
                  <String, dynamic>{
                    'hazinesses': 'Bank Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your bank account',
                    'dulses': 'txt',
                  },
                ],
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationBindCard,
      arguments: <String, dynamic>{
        'routeKey': 'bank',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Informasi bank',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('E-wallet Account'), findsOneWidget);
    expect(find.text('Bank Account'), findsNothing);

    await tester.tap(find.byKey(const Key('certification_bind_card_tab_2')));
    await tester.pumpAndSettle();

    expect(find.text('Bank Account'), findsOneWidget);
    expect(find.text('E-wallet Account'), findsNothing);
    expect(
      find.byKey(const Key('certification_bind_card_channelCode_selector')),
      findsOneWidget,
    );
  });

  testWidgets(
    'bind card page does not refocus previous input after enum sheet closes',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          bindCardInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Bank',
                  'outcrop': 2,
                  'tingling': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'hazinesses': 'Select your recipient bank',
                      'unplait': 'channelCode',
                      'tissual': 'Please select your recipient bank',
                      'dulses': 'enum',
                      'scabiosa': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'governmental': 'Union Bank',
                          'outcrop': 'UBP',
                        },
                      ],
                    },
                    <String, dynamic>{
                      'hazinesses': 'First Name',
                      'unplait': 'firstName',
                      'tissual': 'First Name',
                      'dulses': 'txt',
                      'disrelished': '',
                    },
                  ],
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final firstNameField = find.byKey(
        const Key('certification_bind_card_firstName_input'),
      );
      await tester.tap(firstNameField);
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(of: firstNameField, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.tap(
        find.byKey(const Key('certification_bind_card_channelCode_selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(editable.focusNode.hasFocus, isFalse);
    },
  );

  testWidgets('bind card page selects first returned group by default', (
    WidgetTester tester,
  ) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        bindCardInfoResponseData: const <String, dynamic>{
          'rekeys': <String, dynamic>{
            'tingling': <Map<String, dynamic>>[
              <String, dynamic>{
                'hazinesses': 'E-wallet',
                'outcrop': 1,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient E-wallet',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient E-wallet',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'GCash e-wallet',
                        'outcrop': 'GCASH',
                      },
                    ],
                    'triadisms': 'GCash e-wallet',
                    'disrelished': 'GCASH',
                  },
                  <String, dynamic>{
                    'hazinesses': 'E-wallet Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your E-Wallet account',
                    'dulses': 'txt',
                  },
                ],
              },
              <String, dynamic>{
                'hazinesses': 'Bank',
                'outcrop': 2,
                'tingling': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'hazinesses': 'Select your recipient bank',
                    'unplait': 'channelCode',
                    'tissual': 'Please select your recipient bank',
                    'dulses': 'enum',
                    'scabiosa': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'governmental': 'Union Bank',
                        'outcrop': 'UBP',
                      },
                    ],
                    'triadisms': 'Union Bank',
                    'disrelished': 'UBP',
                  },
                  <String, dynamic>{
                    'hazinesses': 'Bank Account',
                    'unplait': 'cardNo',
                    'tissual': 'Please entry your bank account',
                    'dulses': 'txt',
                  },
                ],
              },
            ],
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationBindCard,
      arguments: <String, dynamic>{
        'routeKey': 'bank',
        'payload': <String, dynamic>{
          'nextStepTitle': 'Informasi bank',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('GCash e-wallet'), findsOneWidget);
    expect(find.text('E-wallet Account'), findsOneWidget);
    expect(find.text('Bank Account'), findsNothing);
  });

  testWidgets(
    'bind card page treats obfuscated enum and txt types like personal info',
    (WidgetTester tester) async {
      Get.put<ApiService>(
        _FakeApiService(
          expectedProductId: '123',
          responseData: const <String, dynamic>{},
          bindCardInfoResponseData: const <String, dynamic>{
            'rekeys': <String, dynamic>{
              'tingling': <Map<String, dynamic>>[
                <String, dynamic>{
                  'hazinesses': 'Bank',
                  'outcrop': 2,
                  'tingling': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'hazinesses': 'Select your recipient bank',
                      'unplait': 'channelCode',
                      'tissual': 'Please select your recipient bank',
                      'dulses': 'Ataractics',
                      'scabiosa': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'governmental': 'Union Bank',
                          'outcrop': 'UBP',
                        },
                      ],
                    },
                    <String, dynamic>{
                      'hazinesses': 'Bank Account',
                      'unplait': 'cardNo',
                      'tissual': 'Please entry your bank account',
                      'dulses': 'Craniosacral',
                    },
                  ],
                },
              ],
            },
          },
        ),
        permanent: true,
      );

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationBindCard,
        arguments: <String, dynamic>{
          'routeKey': 'bank',
          'payload': <String, dynamic>{
            'nextStepTitle': 'Informasi bank',
            'productId': '123',
          },
        },
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('certification_bind_card_channelCode_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('certification_bind_card_channelCode_input')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('certification_bind_card_cardNo_input')),
        findsOneWidget,
      );
    },
  );

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
  Widget Function()? workInfoPageBuilder,
  Widget Function()? bindCardPageBuilder,
  Widget Function()? webViewPageBuilder,
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
      GetPage(
        name: AppRoutes.certificationWorkInfo,
        page: workInfoPageBuilder ?? () => const CertificationWorkInfoPage(),
      ),
      GetPage(
        name: AppRoutes.certificationBindCard,
        page: bindCardPageBuilder ?? () => const CertificationBindCardPage(),
      ),
      GetPage(
        name: AppRoutes.webview,
        page:
            webViewPageBuilder ?? () => const Scaffold(body: SizedBox.shrink()),
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
    this.bindCardInfoResponseData = const <String, dynamic>{},
    this.bindCardSubmitResponseData = const <String, dynamic>{},
    this.changeBankCardResponseData = const <String, dynamic>{},
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
  final Map<String, dynamic> bindCardInfoResponseData;
  final Map<String, dynamic> bindCardSubmitResponseData;
  final Map<String, dynamic> changeBankCardResponseData;
  final String expectedProductId;
  final Object? fetchError;
  int fetchAddressOptionsCallCount = 0;
  String? uploadedFilePath;
  Map<String, dynamic> uploadedBody = const <String, dynamic>{};
  Map<String, dynamic> savedIdentityBody = const <String, dynamic>{};
  Map<String, dynamic> savedUserInfoBody = const <String, dynamic>{};
  Map<String, dynamic> savedWorkInfoBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedBindCardInfoParams = const <String, dynamic>{};
  Map<String, dynamic> submittedBindCardBody = const <String, dynamic>{};
  Map<String, dynamic> changedBankCardBody = const <String, dynamic>{};
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
  Future<NetworkResponse> fetchWorkInfo(Map<String, dynamic> params) async {
    expect(params['cohabiter'], expectedProductId);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(userInfoResponseData),
      raw: userInfoResponseData,
    );
  }

  @override
  Future<NetworkResponse> fetchBindCardInfo(Map<String, dynamic> params) async {
    fetchedBindCardInfoParams = Map<String, dynamic>.from(params);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(bindCardInfoResponseData),
      raw: bindCardInfoResponseData,
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

  @override
  Future<NetworkResponse> saveWorkInfo(Map<String, dynamic> body) async {
    savedWorkInfoBody = body;
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(const <String, dynamic>{}),
      raw: const <String, dynamic>{},
    );
  }

  @override
  Future<NetworkResponse> submitBindCard({
    required Map<String, dynamic> body,
    String? filePath,
  }) async {
    submittedBindCardBody = Map<String, dynamic>.from(body);
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(bindCardSubmitResponseData),
      raw: bindCardSubmitResponseData,
    );
  }

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
