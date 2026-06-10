import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';
import 'package:funny_loan/app/modules/certification_step/views/certification_face_page.dart';
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
  MethodCall? latestTrustDecisionCall;

  setUp(() {
    latestTrustDecisionCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(trustDecisionChannel, (call) async {
          latestTrustDecisionCall = call;
          if (call.method != 'showTrustDecisionLiveness') {
            return null;
          }
          return <String, dynamic>{
            'success': true,
            'code': 0,
            'message': 'ok',
            'raw': <String, dynamic>{'sequenceId': 'face-seq'},
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
    expect(find.byKey(const Key('certification_face_demo_image')), findsOneWidget);
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
        facePageBuilder:
            () => CertificationFacePage(
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
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Liveness verification succeeded'), findsOneWidget);
    expect(latestTrustDecisionCall?.arguments, 'td-token');
    await tester.pump(const Duration(seconds: 3));
  });

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
        facePageBuilder:
            () => CertificationFacePage(
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
        facePageBuilder:
            () => CertificationFacePage(
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
        facePageBuilder:
            () => CertificationFacePage(
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
        facePageBuilder:
            () => CertificationFacePage(
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
      AppDataStore.setCache(AppDataStore.productDetailScabiosaCacheKey, <
        String,
        String
      >{
        'extricating': 'cached face top',
      });

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
      AppDataStore.setCache(AppDataStore.productDetailScabiosaCacheKey, <
        String,
        String
      >{
        'beveling': 'cached upload top',
      });

      await tester.pumpWidget(_buildTestApp());

      Get.toNamed<dynamic>(
        AppRoutes.certificationUpload,
        arguments: <String, dynamic>{
          'payload': <String, dynamic>{'nextStepTitle': 'Identity verification'},
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
        successPageBuilder:
            () => CertificationUploadSuccessPage(
              productDetailFetcher: (productId) async => <String, dynamic>{},
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
      Map<String, dynamic>? dispatchedProductDetail;

      await tester.pumpWidget(
        _buildTestApp(
          successPageBuilder:
              () => CertificationUploadSuccessPage(
                productDetailFetcher: (productId) async {
                  fetchedProductId = productId;
                  return <String, dynamic>{'nextStepCode': 'Hoarily'};
                },
                productDetailNavigator: (productDetail) async {
                  dispatchedProductDetail = productDetail;
                  return <String, dynamic>{'handled': true};
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
      expect(
        dispatchedProductDetail,
        <String, dynamic>{'nextStepCode': 'Hoarily'},
      );
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
          successPageBuilder:
              () => CertificationUploadSuccessPage(
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
      await tester.tap(find.byKey(const Key('certification_success_birth_date')));
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
          successPageBuilder:
              () => CertificationUploadSuccessPage(
                birthDatePicker: (context, initialDate) async =>
                    '09-06-1998',
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

      await tester.tap(find.byKey(const Key('certification_success_birth_date')));
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

      await tester.tap(find.byKey(const Key('certification_success_birth_date')));
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
      AppDataStore.setCache(AppDataStore.productDetailScabiosaCacheKey, <
        String,
        String
      >{
        'vicomtes': 'cached success top',
      });

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
  Widget Function()? successPageBuilder,
  Widget Function()? facePageBuilder,
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
        page: successPageBuilder ?? () => const CertificationUploadSuccessPage(),
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
  final String expectedProductId;
  final Object? fetchError;
  String? uploadedFilePath;
  Map<String, dynamic> uploadedBody = const <String, dynamic>{};
  Map<String, dynamic> savedIdentityBody = const <String, dynamic>{};
  Map<String, dynamic> fetchedFaceTokenBody = const <String, dynamic>{};

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
