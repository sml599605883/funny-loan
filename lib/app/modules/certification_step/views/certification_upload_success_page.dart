import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/json/json.dart';
import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';

class CertificationUploadSuccessPage extends StatefulWidget {
  const CertificationUploadSuccessPage({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<CertificationUploadSuccessPage> createState() =>
      _CertificationUploadSuccessPageState();
}

class _CertificationUploadSuccessPageState
    extends State<CertificationUploadSuccessPage> {
  late final ApiService _apiService =
      widget.apiService ?? Get.find<ApiService>();
  late final _CertificationUploadSuccessArgs _pageArgs =
      _CertificationUploadSuccessArgs.from(Get.arguments);
  bool _isSubmitting = false;

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
                  children: [
                    const _SuccessHeader(),
                    SizedBox(height: 16.h),
                    const CertificationUploadHintBanner(
                      text:
                          'A clear ID photo is the key to lightning-fast approval. Please upload ID front.',
                    ),
                    SizedBox(height: 13.h),
                    _SuccessContent(result: _pageArgs.result),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SuccessSubmitButton(
        isSubmitting: _isSubmitting,
        onTap: _isSubmitting ? null : _submitIdentityInfo,
      ),
    );
  }

  Future<void> _submitIdentityInfo() async {
    setState(() => _isSubmitting = true);
    try {
      EasyLoading.show();
      await _apiService.saveIdentityInfo(<String, dynamic>{
        'studiednesses': _pageArgs.result.birthDateForSubmit,
        'underspin': _pageArgs.result.idNumber,
        'governmental': _pageArgs.result.fullName,
        'outcrop': '11',
        'impotencies': _pageArgs.identityType,
      });
      if (!mounted) {
        return;
      }
      EasyLoading.dismiss();
    } catch (error) {
      if (!mounted) {
        return;
      }
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _CertificationUploadSuccessArgs {
  const _CertificationUploadSuccessArgs({
    required this.identityType,
    required this.result,
  });

  factory _CertificationUploadSuccessArgs.from(Object? arguments) {
    final args = arguments is Map ? arguments : const <String, dynamic>{};
    return _CertificationUploadSuccessArgs(
      identityType: (args['identityType'] as String? ?? '').trim(),
      result: CertificationUploadSuccessResult.fromJson(args['result']),
    );
  }

  final String identityType;
  final CertificationUploadSuccessResult result;
}

class CertificationUploadSuccessResult {
  const CertificationUploadSuccessResult({
    required this.fullName,
    required this.idNumber,
    required this.birthDate,
    required this.cardImageUrl,
  });

  factory CertificationUploadSuccessResult.fromJson(Object? value) {
    final json = Json(value);
    final birthDate = json['studiednesses'].stringValue.trim();
    return CertificationUploadSuccessResult(
      fullName: json['governmental'].stringValue.trim(),
      idNumber: json['underspin'].stringValue.trim(),
      birthDate: birthDate.isNotEmpty
          ? birthDate
          : _joinDateParts(
              json['intermale'].stringValue,
              json['grenadier'].stringValue,
              json['miscaller'].stringValue,
            ),
      cardImageUrl: json['sidearms'].stringValue.trim(),
    );
  }

  final String fullName;
  final String idNumber;
  final String birthDate;
  final String cardImageUrl;

  String get birthDateForSubmit {
    final normalized = birthDate.trim().replaceAll('/', '-');
    final parts = normalized.split('-');
    if (parts.length != 3) {
      return normalized;
    }
    if (parts.first.length == 4) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return normalized;
  }

  static String _joinDateParts(String year, String month, String day) {
    final normalizedYear = year.trim();
    final normalizedMonth = month.trim();
    final normalizedDay = day.trim();
    if (normalizedYear.isEmpty ||
        normalizedMonth.isEmpty ||
        normalizedDay.isEmpty) {
      return '';
    }
    return '$normalizedYear/$normalizedMonth/$normalizedDay';
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

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
              'Identity verification',
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

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.result});

  final CertificationUploadSuccessResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(45.r)),
      ),
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 20,
        top: 23,
        right: 20,
        bottom: 103,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _IdPreview(imageUrl: result.cardImageUrl)),
          SizedBox(height: 32.h),
          _InfoField(label: 'Full Name', value: result.fullName),
          SizedBox(height: 18.h),
          _InfoField(label: 'ID No.', value: result.idNumber),
          SizedBox(height: 18.h),
          _InfoField(label: 'Date of Birth', value: result.birthDate),
        ],
      ),
    );
  }
}

class _IdPreview extends StatelessWidget {
  const _IdPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.isEmpty
        ? Image.asset(
            'assets/certification/certification_upload_preview.png',
            fit: BoxFit.cover,
          )
        : Image.network(imageUrl, fit: BoxFit.cover);
    return Container(
      width: 293.w,
      height: 184.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.certificationUploadSuccessBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.certificationUploadSuccessLabel,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 14 / 12,
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          width: double.infinity,
          height: 39.h,
          alignment: Alignment.centerLeft,
          padding: ScreenAdapter.edgeInsetsOnly(left: 12, right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.certificationUploadSuccessInputBorder,
            ),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.certificationUploadDialogText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 17 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessSubmitButton extends StatelessWidget {
  const _SuccessSubmitButton({required this.isSubmitting, required this.onTap});

  final bool isSubmitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: ScreenAdapter.edgeInsetsOnly(left: 56, right: 56, bottom: 7),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: isSubmitting ? 0.6 : 1,
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
      ),
    );
  }
}
