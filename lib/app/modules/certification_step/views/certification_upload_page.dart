import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/app_permission_service.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../report/report_manager.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';

abstract class CertificationUploadImagePicker {
  Future<String?> pickFromCamera();

  Future<String?> pickFromGallery();
}

abstract class CertificationUploadImageCompressor {
  Future<String?> compressToLimit(String filePath);
}

class ImagePickerCertificationUploadImagePicker
    implements CertificationUploadImagePicker {
  ImagePickerCertificationUploadImagePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickFromCamera() async {
    final status = await AppPermissionService.requestCamera();
    if (!status.isGranted) {
      return null;
    }
    final file = await _imagePicker.pickImage(source: ImageSource.camera);
    return file?.path;
  }

  @override
  Future<String?> pickFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }
}

class DefaultCertificationUploadImageCompressor
    implements CertificationUploadImageCompressor {
  static const int _targetBytes = 500 * 1024;

  @override
  Future<String?> compressToLimit(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    var quality = 90;
    File compressedFile = file;
    while (quality >= 10) {
      final qualityCompressedFile = await _compressImageQuality(
        compressedFile,
        quality,
      );
      if (qualityCompressedFile == null) {
        return null;
      }
      compressedFile = qualityCompressedFile;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
      quality -= 5;
    }

    final bytes = await compressedFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    var currentWidth = frame.image.width;
    var currentHeight = frame.image.height;

    while (currentWidth > 100 && currentHeight > 100) {
      currentWidth = (currentWidth * 0.95).toInt();
      currentHeight = (currentHeight * 0.95).toInt();
      final sizeCompressedFile = await _compressImageSize(
        file,
        currentWidth,
        currentHeight,
      );
      if (sizeCompressedFile == null) {
        return null;
      }
      compressedFile = sizeCompressedFile;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
    }
    return compressedFile.path;
  }

  Future<File?> _compressImageQuality(File file, int quality) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/certification_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: false,
      keepExif: false,
    );
    if (result == null) {
      return null;
    }
    return File(result.path);
  }

  Future<File?> _compressImageSize(File file, int width, int height) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/certification_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: width,
      minHeight: height,
      quality: 95,
      format: CompressFormat.jpeg,
    );
    if (result == null) {
      return null;
    }
    return File(result.path);
  }
}

class CertificationUploadPage extends StatefulWidget {
  const CertificationUploadPage({
    super.key,
    this.imagePicker,
    this.apiService,
    this.imageCompressor,
  });

  final CertificationUploadImagePicker? imagePicker;
  final ApiService? apiService;
  final CertificationUploadImageCompressor? imageCompressor;

  @override
  State<CertificationUploadPage> createState() =>
      _CertificationUploadPageState();
}

class _CertificationUploadPageState extends State<CertificationUploadPage> {
  late final CertificationUploadImagePicker _imagePicker =
      widget.imagePicker ?? ImagePickerCertificationUploadImagePicker();
  late final CertificationUploadImageCompressor _imageCompressor =
      widget.imageCompressor ?? DefaultCertificationUploadImageCompressor();
  late final ApiService _apiService =
      widget.apiService ?? Get.find<ApiService>();
  bool _isUploading = false;
  late final String _pageStartTime = _currentSecondsTimestamp();
  String _identityUploadStartTime = '';

  @override
  void initState() {
    super.initState();
    _reportRiskScene(
      ReportRiskScene.identityUploadEnter,
      startTime: _pageStartTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationUploadBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const AppPageHeader(title: 'Identity verification'),
                    SizedBox(height: 16.h),
                    const CertificationUploadHintBanner(
                      scabiosaFieldKey: 'beveling',
                      text: 'Snap your valid ID Clear photo, quick check',
                    ),
                    SizedBox(height: 13.h),
                    Container(
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
                        bottom: 100,
                      ),
                      child: Image.asset(
                        'assets/certification/certification_upload_preview.png',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _UploadSubmitButton(
        isUploading: _isUploading,
        onTap: _isUploading ? null : () => _showUploadSourceDialog(context),
      ),
    );
  }

  void _showUploadSourceDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.certificationUploadDialogBarrier,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      isScrollControlled: true,
      builder: (sheetContext) => _UploadSourceSheet(
        onPhotograph: () => _pickAndUpload(sheetContext, _UploadSource.camera),
        onPhotoAlbum: () => _pickAndUpload(sheetContext, _UploadSource.gallery),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext sheetContext,
    _UploadSource source,
  ) async {
    Navigator.of(sheetContext).pop();
    EasyLoading.show();
    _identityUploadStartTime = _currentSecondsTimestamp();
    final filePath = source == _UploadSource.camera
        ? await _imagePicker.pickFromCamera()
        : await _imagePicker.pickFromGallery();
    if (filePath == null || filePath.isEmpty) {
      EasyLoading.dismiss();
      return;
    }
    final compressedPath = await _imageCompressor.compressToLimit(filePath);
    if (compressedPath == null || compressedPath.isEmpty) {
      EasyLoading.dismiss();
      return;
    }
    await _uploadSelectedFile(compressedPath, source);
  }

  Future<void> _uploadSelectedFile(
    String filePath,
    _UploadSource source,
  ) async {
    if (_isUploading) {
      return;
    }
    setState(() => _isUploading = true);
    try {
      final response = await _apiService.uploadIdentityOrFace(
        body: _uploadBody(source),
        filePath: filePath,
      );
      if (!mounted) {
        return;
      }
      EasyLoading.dismiss();
      debugPrint('Upload identity photo success: ${response.message}');
      NavigationHelper.toCertificationUploadSuccess<void>(
        arguments: <String, dynamic>{
          'identityType': _identityType(),
          'productId': _productId(),
          'orderNo': _orderNo(),
          'startTime': _identityUploadStartTime,
          'result': response.data.mapValue,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Map<String, dynamic> _uploadBody(_UploadSource source) {
    return <String, dynamic>{
      'outcrop': '11',
      'blessedness': source == _UploadSource.gallery ? '1' : '2',
      'impotencies': _identityType(),
    };
  }

  String _identityType() {
    final arguments = Get.arguments;
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    final selectedIdentityValue = _payloadString(
      payloadMap['selectedIdentityValue'],
    );
    return selectedIdentityValue.isNotEmpty
        ? selectedIdentityValue
        : _payloadString(payloadMap['selectedIdentityTitle']);
  }

  String _productId() {
    final arguments = Get.arguments;
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    return _payloadString(payloadMap['productId']);
  }

  String _orderNo() {
    final arguments = Get.arguments;
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    return _payloadString(payloadMap['orderNo']);
  }

  void _reportRiskScene(String sceneType, {required String startTime}) {
    if (!Get.isRegistered<ReportManager>()) {
      return;
    }
    unawaited(
      Get.find<ReportManager>().reportRiskScene(
        sceneType: sceneType,
        productId: _productId(),
        orderNo: _orderNo(),
        startTime: startTime,
      ),
    );
  }

  String _payloadString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String _currentSecondsTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }
}

enum _UploadSource { camera, gallery }

class _UploadSourceSheet extends StatefulWidget {
  const _UploadSourceSheet({
    required this.onPhotograph,
    required this.onPhotoAlbum,
  });

  final VoidCallback onPhotograph;
  final VoidCallback onPhotoAlbum;

  @override
  State<_UploadSourceSheet> createState() => _UploadSourceSheetState();
}

class _UploadSourceSheetState extends State<_UploadSourceSheet> {
  _UploadSource? _selectedSource;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ScreenAdapter.edgeInsetsOnly(left: 15, right: 15, bottom: 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: ScreenAdapter.edgeInsetsOnly(
              left: 9,
              top: 22,
              right: 10,
              bottom: 22,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              children: [
                _UploadSourceRow(
                  iconPath:
                      'assets/certification/certification_upload_camera.png',
                  title: 'Photograph',
                  trailing: _selectedSource == _UploadSource.camera
                      ? _SelectedUploadSourceIndicator()
                      : null,
                  onTap: () =>
                      setState(() => _selectedSource = _UploadSource.camera),
                ),
                SizedBox(height: 22.h),
                Container(
                  width: double.infinity,
                  height: 2.h,
                  color: AppColors.certificationUploadDialogDivider,
                ),
                SizedBox(height: 21.h),
                _UploadSourceRow(
                  iconPath:
                      'assets/certification/certification_upload_album.png',
                  title: 'Photo Album',
                  trailing: _selectedSource == _UploadSource.gallery
                      ? _SelectedUploadSourceIndicator()
                      : null,
                  onTap: () =>
                      setState(() => _selectedSource = _UploadSource.gallery),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _UploadSourceActionButton(
                title: 'Cancel',
                textColor: AppColors.certificationUploadDialogCancelText,
                backgroundColor: Colors.white,
                onTap: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 10.w),
              _UploadSourceActionButton(
                title: 'Done',
                textColor: Colors.white,
                backgroundColor: AppColors.certificationUploadDialogConfirm,
                fontWeight: FontWeight.w700,
                onTap: () {
                  if (_selectedSource == _UploadSource.camera) {
                    widget.onPhotograph();
                    return;
                  }
                  if (_selectedSource == _UploadSource.gallery) {
                    widget.onPhotoAlbum();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedUploadSourceIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/certification/check_icon.png',
      width: 20.w,
      height: 20.h,
      fit: BoxFit.contain,
    );
  }
}

class _UploadSourceRow extends StatelessWidget {
  const _UploadSourceRow({
    required this.iconPath,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final String iconPath;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: ScreenAdapter.edgeInsetsOnly(left: 11, right: 6),
        child: Row(
          children: [
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    iconPath,
                    width: 30.w,
                    height: 30.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 15.w),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.certificationUploadDialogText,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                      height: 22 / 18,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _UploadSourceActionButton extends StatelessWidget {
  const _UploadSourceActionButton({
    required this.title,
    required this.textColor,
    required this.backgroundColor,
    required this.onTap,
    this.fontWeight = FontWeight.w400,
  });

  final String title;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 144.w,
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18.sp,
            fontWeight: fontWeight,
            height: 22 / 18,
          ),
        ),
      ),
    );
  }
}

class _UploadSubmitButton extends StatelessWidget {
  const _UploadSubmitButton({required this.isUploading, required this.onTap});

  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: ScreenAdapter.edgeInsetsOnly(left: 72, right: 72, bottom: 20),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 232.w,
            height: 48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(0xFF3A57B0),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Text(
              isUploading ? 'Uploading' : 'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
