import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/native/native_bridge.dart';
import '../../../core/permissions/app_permission_service.dart';
import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';

typedef CameraPermissionRequester = Future<PermissionStatus> Function();
typedef AppSettingsOpener = Future<bool> Function();
typedef FaceTokenFetcher = Future<FaceTokenResult> Function(Map<String, dynamic> body);
typedef TrustDecisionLivenessLauncher =
    Future<TrustDecisionLivenessResult> Function(String unwarned);

class FaceTokenResult {
  const FaceTokenResult({
    required this.grayly,
    required this.unwarned,
    required this.cithrens,
  });

  final int grayly;
  final String unwarned;
  final String cithrens;
}

class CertificationFacePage extends StatelessWidget {
  const CertificationFacePage({
    super.key,
    this.requestCameraPermission = AppPermissionService.requestCamera,
    this.openAppSettingsPage = AppPermissionService.openAppSettingsPage,
    this.fetchFaceToken = _defaultFetchFaceToken,
    this.showTrustDecisionLiveness = NativeBridge.showTrustDecisionLiveness,
  });

  final CameraPermissionRequester requestCameraPermission;
  final AppSettingsOpener openAppSettingsPage;
  final FaceTokenFetcher fetchFaceToken;
  final TrustDecisionLivenessLauncher showTrustDecisionLiveness;

  @override
  Widget build(BuildContext context) {
    final pageArgs = _CertificationFaceArgs.from(Get.arguments);
    return Scaffold(
      backgroundColor: AppColors.certificationUploadBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _FaceHeader(title: pageArgs.displayTitle),
                    SizedBox(height: 16.h),
                    const CertificationUploadHintBanner(
                      scabiosaFieldKey: 'extricating',
                      text:
                          'Please keep your face clear and centered in the frame.',
                    ),
                    SizedBox(height: 13.h),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(45.r),
                        ),
                      ),
                      padding: ScreenAdapter.edgeInsetsOnly(
                        left: 20,
                        top: 20,
                        right: 20,
                        bottom: 130,
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          // color: Colors.black,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          key: const Key('certification_face_demo_image'),
                          'assets/certification/certification_face_demo.png',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FaceSubmitButton(
        onTap: () async {
          EasyLoading.show();
          final permissionStatus = await requestCameraPermission();
          if (!context.mounted) {
            return;
          }
          if (!permissionStatus.isGranted) {
            EasyLoading.dismiss();
            await _showCameraPermissionDialog(context);
            return;
          }
          final faceTokenResult = await fetchFaceToken(
            pageArgs.faceTokenRequestBody,
          );
          if (!context.mounted) {
            EasyLoading.dismiss();
            return;
          }
          if (faceTokenResult.grayly == 400) {
            EasyLoading.dismiss();
            await _showReuploadIdentityDialog(context);
            return;
          }
          if (faceTokenResult.grayly != 200) {
            EasyLoading.dismiss();
            EasyLoading.showToast(
              faceTokenResult.cithrens.isNotEmpty
                  ? faceTokenResult.cithrens
                  : 'Failed to get face token',
            );
            return;
          }
          if (faceTokenResult.unwarned.isEmpty) {
            EasyLoading.dismiss();
            EasyLoading.showToast('Failed to get face token');
            return;
          }

          EasyLoading.dismiss();
          final result = await showTrustDecisionLiveness(
            faceTokenResult.unwarned,
          );
          if (result.success) {
            EasyLoading.showSuccess('Liveness verification succeeded');
            return;
          }
          EasyLoading.showToast(
            result.message.isNotEmpty
                ? result.message
                : 'Liveness verification failed',
          );
        },
      ),
    );
  }

  Future<void> _showCameraPermissionDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Camera permission required'),
          content: const Text(
            'Please enable camera access in Settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettingsPage();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReuploadIdentityDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Please re-upload your ID photo'),
          content: const Text(
            'Your ID photo needs to be uploaded again before face verification.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('CertificationFacePage reupload dialog cancel tapped');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                debugPrint('CertificationFacePage reupload dialog upload tapped');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  static Future<FaceTokenResult> _defaultFetchFaceToken(
    Map<String, dynamic> body,
  ) async {
    final response = await Get.find<ApiService>().fetchFaceToken(body);
    return FaceTokenResult(
      grayly: response.data['grayly'].intOrNull ?? 0,
      unwarned: response.data['unwarned'].stringValue,
      cithrens: response.data['cithrens'].stringValue,
    );
  }
}

class _FaceHeader extends StatelessWidget {
  const _FaceHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.certificationTextPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                height: 24 / 20,
              ),
            ),
          ),
          Positioned(
            left: 11.w,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => NavigationHelper.back<void>(),
              child: Image.asset(
                'assets/icon_back.png',
                width: 25.w,
                height: 25.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceSubmitButton extends StatelessWidget {
  const _FaceSubmitButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: ScreenAdapter.edgeInsetsOnly(left: 56, right: 56, bottom: 7),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            onTap();
          },
          child: Container(
            height: 50.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.certificationUploadSuccessButton,
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 22 / 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificationFaceArgs {
  const _CertificationFaceArgs({required this.title, required this.payloadMap});

  factory _CertificationFaceArgs.from(Object? arguments) {
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    return _CertificationFaceArgs(
      title: (payloadMap['nextStepTitle'] as String? ?? '').trim(),
      payloadMap: Map<String, dynamic>.from(payloadMap),
    );
  }

  final String title;
  final Map<String, dynamic> payloadMap;

  String get displayTitle {
    if (title.isNotEmpty) {
      return title;
    }
    return 'Face verification';
  }

  Map<String, dynamic> get faceTokenRequestBody => payloadMap;
}
