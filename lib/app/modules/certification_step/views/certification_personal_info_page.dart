import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/json/json.dart';
import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import '../models/address_option.dart';
import '../models/address_selection.dart';
import '../models/certification_personal_info_args.dart';
import '../models/personal_info_field_data.dart';
import '../models/personal_info_field_option.dart';
import 'widgets/address_selection_sheet.dart';
import 'widgets/enum_selection_sheet.dart';

typedef PersonalInfoProductDetailFlowRunner =
    Future<void> Function(String productId);

class CertificationPersonalInfoPage extends StatefulWidget {
  const CertificationPersonalInfoPage({
    super.key,
    this.apiService,
    this.productDetailFlowRunner =
        ApiNavigationHelper.fetchProductDetailByProductId,
  });

  final ApiService? apiService;
  final PersonalInfoProductDetailFlowRunner productDetailFlowRunner;

  @override
  State<CertificationPersonalInfoPage> createState() =>
      _CertificationPersonalInfoPageState();
}

class _CertificationPersonalInfoPageState
    extends State<CertificationPersonalInfoPage> {
  late final ApiService _apiService =
      widget.apiService ?? Get.find<ApiService>();
  late final CertificationPersonalInfoArgs _pageArgs =
      CertificationPersonalInfoArgs.from(Get.arguments);
  List<PersonalInfoFieldData> _fields = const <PersonalInfoFieldData>[];
  List<AddressOption>? _cachedAddressOptions;
  Future<List<AddressOption>>? _addressOptionsFuture;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _prefetchAddressOptions();
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
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
            _PersonalInfoHeader(title: _pageArgs.displayTitle),
            SizedBox(height: 16.h),
            const CertificationUploadHintBanner(
              scabiosaFieldKey: 'verves',
              text:
                  'A clear ID photo is the key to lightning-fast approval. Please upload ID front.',
            ),
            SizedBox(height: 25.h),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45.r),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: ScreenAdapter.edgeInsetsOnly(
                    left: 20,
                    top: 13,
                    right: 20,
                    bottom: 24,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PersonalInfoSubmitButton(
        isSubmitting: _isSubmitting,
        onTap: _isSubmitting ? null : _submitUserInfo,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SizedBox(
        height: 420.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SizedBox(
        height: 420.h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.certificationTextPrimary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: _loadUserInfo,
                child: Container(
                  padding: ScreenAdapter.edgeInsetsSymmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.certificationUploadSuccessButton,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PersonalInfoProgress(),
        SizedBox(height: 23.h),
        for (var index = 0; index < _fields.length; index++) ...[
          _PersonalInfoField(
            field: _fields[index],
            onTap: () => _handleFieldTap(_fields[index]),
          ),
          if (index != _fields.length - 1) SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Future<void> _loadUserInfo() async {
    final productId = _pageArgs.productId;
    if (productId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.fetchUserInfo(<String, dynamic>{
        'cohabiter': productId,
      });
      final fields = _parseFields(response.raw);
      if (!mounted) {
        for (final field in fields) {
          field.dispose();
        }
        return;
      }
      _replaceFields(fields);
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = NetworkErrorMapper.map(error);
      });
    }
  }

  List<PersonalInfoFieldData> _parseFields(Object? raw) {
    final json = Json(raw);
    final fields = json['rekeys']['tingling'].listValue.isNotEmpty
        ? json['rekeys']['tingling'].listValue
        : json['tingling'].listValue;
    return fields
        .map(PersonalInfoFieldData.fromJson)
        .where((field) => field.label.isNotEmpty && field.saveKey.isNotEmpty)
        .toList();
  }

  void _replaceFields(List<PersonalInfoFieldData> nextFields) {
    for (final field in _fields) {
      field.dispose();
    }
    _fields = nextFields;
  }

  Future<void> _clearActiveFocus() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _handleFieldTap(PersonalInfoFieldData field) async {
    if (field.isTextInput) {
      return;
    }
    if (field.isCitySelect) {
      await _handleAddressFieldTap(field);
      return;
    }
    await _clearActiveFocus();
    if (!mounted) {
      return;
    }

    if (field.options.isEmpty) {
      EasyLoading.showToast(
        field.placeholder.isNotEmpty
            ? field.placeholder
            : 'Please select ${field.label}',
      );
      return;
    }

    final selectedOption = await showModalBottomSheet<PersonalInfoFieldOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.certificationUploadDialogBarrier,
      builder: (sheetContext) {
        return EnumSelectionSheet(
          options: field.options,
          currentValue: field.currentSubmitValue,
        );
      },
    );
    if (selectedOption == null || !mounted) {
      return;
    }
    setState(() {
      field.selectOption(selectedOption);
    });
  }

  Future<void> _handleAddressFieldTap(PersonalInfoFieldData field) async {
    final shouldShowLoading =
        _cachedAddressOptions == null && _addressOptionsFuture == null;
    try {
      await _clearActiveFocus();
      if (shouldShowLoading) {
        EasyLoading.show();
      }
      final addressOptions = await _getAddressOptions();
      if (shouldShowLoading) {
        EasyLoading.dismiss();
      }
      if (!mounted) {
        return;
      }
      if (addressOptions.isEmpty) {
        EasyLoading.showToast(
          field.placeholder.isNotEmpty
              ? field.placeholder
              : 'Please select ${field.label}',
        );
        return;
      }
      final selectedAddress = await showModalBottomSheet<AddressSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.certificationUploadDialogBarrier,
        builder: (sheetContext) {
          return AddressSelectionSheet(
            title: field.label,
            options: addressOptions,
            currentValue: field.controller.text.trim(),
          );
        },
      );
      if (selectedAddress == null || !mounted) {
        return;
      }
      setState(() {
        field.selectAddress(selectedAddress);
      });
    } catch (error) {
      if (shouldShowLoading) {
        EasyLoading.dismiss();
      }
      if (!mounted) {
        return;
      }
      EasyLoading.showError(NetworkErrorMapper.map(error));
    }
  }

  void _prefetchAddressOptions() {
    _getAddressOptions().catchError((_) => <AddressOption>[]);
  }

  Future<List<AddressOption>> _getAddressOptions() {
    final cached = _cachedAddressOptions;
    if (cached != null && cached.isNotEmpty) {
      return Future<List<AddressOption>>.value(cached);
    }
    final inFlight = _addressOptionsFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _fetchAddressOptions();
    _addressOptionsFuture = future;
    return future;
  }

  Future<List<AddressOption>> _fetchAddressOptions() async {
    try {
      final response = await _apiService.fetchAddressOptions();
      final addressOptions = AddressOption.parseList(response.data);
      _cachedAddressOptions = addressOptions;
      return addressOptions;
    } finally {
      _addressOptionsFuture = null;
    }
  }

  Future<void> _submitUserInfo() async {
    final productId = _pageArgs.productId;
    if (productId.isEmpty) {
      return;
    }

    final body = <String, dynamic>{'cohabiter': productId};
    for (final field in _fields) {
      body[field.saveKey] = field.currentSubmitValue;
    }

    setState(() => _isSubmitting = true);
    try {
      EasyLoading.show();
      await _apiService.saveUserInfo(body);
      await widget.productDetailFlowRunner(productId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      EasyLoading.dismiss();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _PersonalInfoHeader extends StatelessWidget {
  const _PersonalInfoHeader({required this.title});

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
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
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

class _PersonalInfoProgress extends StatelessWidget {
  const _PersonalInfoProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/certification/certification_personal_progress_step1.png',
        width: 343.w,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class _PersonalInfoField extends StatelessWidget {
  const _PersonalInfoField({required this.field, required this.onTap});

  final PersonalInfoFieldData field;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(
            color: AppColors.certificationUploadSuccessLabel,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 14 / 12,
          ),
        ),
        SizedBox(height: 7.h),
        if (field.isSelectable)
          GestureDetector(
            key: Key('certification_personal_info_${field.saveKey}_selector'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: _PersonalInfoFieldContainer(
              isAddressField: field.isCitySelect,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      field.displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: field.hasValue
                            ? AppColors.certificationUploadDialogText
                            : AppColors.certificationUploadSuccessLabel,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Image.asset(
                    'assets/certification/certification_personal_field_arrow.png',
                    width: 15.w,
                    height: 10.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.w,
                      color: AppColors.certificationUploadSuccessLabel,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _PersonalInfoFieldContainer(
            child: TextField(
              key: Key('certification_personal_info_${field.saveKey}_input'),
              controller: field.controller,
              keyboardType: field.isNumeric
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: field.placeholder.isNotEmpty
                    ? field.placeholder
                    : 'Please enter',
                hintStyle: TextStyle(
                  color: AppColors.certificationUploadSuccessLabel,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.zero,
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

class _PersonalInfoFieldContainer extends StatelessWidget {
  const _PersonalInfoFieldContainer({
    required this.child,
    this.isAddressField = false,
  });

  final Widget child;
  final bool isAddressField;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: ScreenAdapter.edgeInsetsOnly(
        left: isAddressField ? 16 : 12,
        right: isAddressField ? 16 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isAddressField ? 19.r : 20.r),
        border: Border.all(
          color: AppColors.certificationUploadSuccessInputBorder,
        ),
      ),
      child: child,
    );
  }
}

class _PersonalInfoSubmitButton extends StatelessWidget {
  const _PersonalInfoSubmitButton({
    required this.isSubmitting,
    required this.onTap,
  });

  final bool isSubmitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: ScreenAdapter.edgeInsetsOnly(left: 37, right: 37, bottom: 13),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 50.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSubmitting
                  ? AppColors.certificationHintText
                  : AppColors.certificationUploadSuccessButton,
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
