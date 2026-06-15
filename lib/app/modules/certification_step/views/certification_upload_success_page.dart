import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/json/json.dart';
import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';

typedef CertificationBirthDatePicker =
    Future<String?> Function(BuildContext context, DateTime initialDate);
typedef CertificationProductDetailFlowRunner =
    Future<void> Function(String productId);

class CertificationUploadSuccessPage extends StatefulWidget {
  const CertificationUploadSuccessPage({
    super.key,
    this.apiService,
    this.birthDatePicker = _showCertificationBirthDatePicker,
    this.productDetailFlowRunner =
        ApiNavigationHelper.fetchProductDetailByProductId,
  });

  final ApiService? apiService;
  final CertificationBirthDatePicker birthDatePicker;
  final CertificationProductDetailFlowRunner productDetailFlowRunner;

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
  late final TextEditingController _fullNameController;
  late final TextEditingController _idNumberController;
  late String _birthDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: _pageArgs.result.fullName,
    );
    _idNumberController = TextEditingController(
      text: _pageArgs.result.idNumber,
    );
    _birthDate = _pageArgs.result.birthDate;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
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
                  children: [
                    const _SuccessHeader(),
                    SizedBox(height: 16.h),
                    const CertificationUploadHintBanner(
                      scabiosaFieldKey: 'vicomtes',
                      text:
                          'A clear ID photo is the key to lightning-fast approval. Please upload ID front.',
                    ),
                    SizedBox(height: 13.h),
                    _SuccessContent(
                      result: _pageArgs.result,
                      fullNameController: _fullNameController,
                      idNumberController: _idNumberController,
                      birthDate: _birthDate,
                      onBirthDateTap: _handleBirthDateTap,
                    ),
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
        'studiednesses': _birthDate.trim(),
        'underspin': _idNumberController.text.trim(),
        'governmental': _fullNameController.text.trim(),
        'outcrop': '11',
        'impotencies': _pageArgs.identityType,
      });
      final productId = _pageArgs.productId;
      if (productId.isNotEmpty) {
        await widget.productDetailFlowRunner(productId);
      }
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

  Future<void> _handleBirthDateTap() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    final selectedBirthDate = await widget.birthDatePicker(
      context,
      _parseBirthDate(_birthDate) ?? DateTime.now(),
    );
    if (!mounted || selectedBirthDate == null || selectedBirthDate.isEmpty) {
      return;
    }
    setState(() => _birthDate = selectedBirthDate);
  }
}

class _CertificationUploadSuccessArgs {
  const _CertificationUploadSuccessArgs({
    required this.identityType,
    required this.productId,
    required this.result,
  });

  factory _CertificationUploadSuccessArgs.from(Object? arguments) {
    final args = arguments is Map ? arguments : const <String, dynamic>{};
    return _CertificationUploadSuccessArgs(
      identityType: (args['identityType'] as String? ?? '').trim(),
      productId: (args['productId'] as String? ?? '').trim(),
      result: CertificationUploadSuccessResult.fromJson(args['result']),
    );
  }

  final String identityType;
  final String productId;
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
      birthDate: _normalizeBirthDate(
        birthDate.isNotEmpty
            ? birthDate
            : _joinDateParts(
                json['intermale'].stringValue,
                json['grenadier'].stringValue,
                json['miscaller'].stringValue,
              ),
      ),
      cardImageUrl: json['sidearms'].stringValue.trim(),
    );
  }

  final String fullName;
  final String idNumber;
  final String birthDate;
  final String cardImageUrl;

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
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    required this.result,
    required this.fullNameController,
    required this.idNumberController,
    required this.birthDate,
    required this.onBirthDateTap,
  });

  final CertificationUploadSuccessResult result;
  final TextEditingController fullNameController;
  final TextEditingController idNumberController;
  final String birthDate;
  final Future<void> Function() onBirthDateTap;

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
          _EditableInfoField(
            fieldKey: const Key('certification_success_full_name_input'),
            label: 'Full Name',
            controller: fullNameController,
          ),
          SizedBox(height: 18.h),
          _EditableInfoField(
            fieldKey: const Key('certification_success_id_number_input'),
            label: 'ID No.',
            controller: idNumberController,
          ),
          SizedBox(height: 18.h),
          _ReadonlyInfoField(
            fieldKey: const Key('certification_success_birth_date'),
            label: 'Date of Birth',
            value: birthDate,
            onTap: onBirthDateTap,
          ),
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

class _EditableInfoField extends StatelessWidget {
  const _EditableInfoField({
    required this.label,
    required this.controller,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.certificationUploadSuccessInputBorder,
            ),
          ),
          child: TextField(
            key: fieldKey,
            controller: controller,
            maxLines: 1,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: ScreenAdapter.edgeInsetsOnly(left: 12, right: 12),
            ),
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

class _ReadonlyInfoField extends StatelessWidget {
  const _ReadonlyInfoField({
    required this.label,
    required this.value,
    required this.onTap,
    this.fieldKey,
  });

  final String label;
  final String value;
  final Future<void> Function() onTap;
  final Key? fieldKey;

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
        GestureDetector(
          key: fieldKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(),
          child: Container(
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
        ),
      ],
    );
  }
}

Future<String?> _showCertificationBirthDatePicker(
  BuildContext context,
  DateTime initialDate,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.certificationUploadDialogBarrier,
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
    isScrollControlled: true,
    builder: (sheetContext) => _BirthDatePickerSheet(initialDate: initialDate),
  );
}

class _BirthDatePickerSheet extends StatefulWidget {
  const _BirthDatePickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_BirthDatePickerSheet> createState() => _BirthDatePickerSheetState();
}

class _BirthDatePickerSheetState extends State<_BirthDatePickerSheet> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ScreenAdapter.edgeInsetsOnly(left: 15, right: 15, bottom: 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: ScreenAdapter.edgeInsetsOnly(top: 18, bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 216.h,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    dateOrder: DatePickerDateOrder.dmy,
                    initialDateTime: widget.initialDate,
                    minimumYear: 1900,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (value) {
                      _selectedDate = value;
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _DatePickerActionButton(
                  title: 'Cancel',
                  textColor: AppColors.certificationUploadDialogCancelText,
                  backgroundColor: Colors.white,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _DatePickerActionButton(
                  title: 'Done',
                  textColor: Colors.white,
                  backgroundColor: AppColors.certificationUploadDialogConfirm,
                  fontWeight: FontWeight.w700,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_formatBirthDate(_selectedDate)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePickerActionButton extends StatelessWidget {
  const _DatePickerActionButton({
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
        height: 50.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25.r),
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

String _normalizeBirthDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final normalized = trimmed.replaceAll('/', '-');
  final parts = normalized.split('-');
  if (parts.length != 3) {
    return trimmed;
  }
  if (parts.first.length == 4) {
    return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
  }
  return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
}

DateTime? _parseBirthDate(String value) {
  final parts = _normalizeBirthDate(value).split('-');
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  return DateTime(year, month, day);
}

String _formatBirthDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$day-$month-$year';
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
