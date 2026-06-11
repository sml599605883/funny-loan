import 'dart:math' as math;

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
  late final _CertificationPersonalInfoArgs _pageArgs =
      _CertificationPersonalInfoArgs.from(Get.arguments);
  List<_PersonalInfoFieldData> _fields = const <_PersonalInfoFieldData>[];
  List<_PersonalAddressOption>? _cachedAddressOptions;
  Future<List<_PersonalAddressOption>>? _addressOptionsFuture;
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

  List<_PersonalInfoFieldData> _parseFields(Object? raw) {
    final json = Json(raw);
    final fields = json['rekeys']['tingling'].listValue.isNotEmpty
        ? json['rekeys']['tingling'].listValue
        : json['tingling'].listValue;
    return fields
        .map(_PersonalInfoFieldData.fromJson)
        .where((field) => field.label.isNotEmpty && field.saveKey.isNotEmpty)
        .toList();
  }

  void _replaceFields(List<_PersonalInfoFieldData> nextFields) {
    for (final field in _fields) {
      field.dispose();
    }
    _fields = nextFields;
  }

  Future<void> _handleFieldTap(_PersonalInfoFieldData field) async {
    if (field.isTextInput) {
      return;
    }
    if (field.isCitySelect) {
      await _handleAddressFieldTap(field);
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

    final selectedOption = await showModalBottomSheet<_PersonalInfoFieldOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.certificationUploadDialogBarrier,
      builder: (sheetContext) {
        return _PersonalEnumSelectionSheet(
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

  Future<void> _handleAddressFieldTap(_PersonalInfoFieldData field) async {
    final shouldShowLoading =
        _cachedAddressOptions == null && _addressOptionsFuture == null;
    try {
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
      final selectedAddress =
          await showModalBottomSheet<_PersonalAddressSelection>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: AppColors.certificationUploadDialogBarrier,
            builder: (sheetContext) {
              return _PersonalAddressSheet(
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
    _getAddressOptions().catchError((_) {});
  }

  Future<List<_PersonalAddressOption>> _getAddressOptions() {
    final cached = _cachedAddressOptions;
    if (cached != null && cached.isNotEmpty) {
      return Future<List<_PersonalAddressOption>>.value(cached);
    }
    final inFlight = _addressOptionsFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _fetchAddressOptions();
    _addressOptionsFuture = future;
    return future;
  }

  Future<List<_PersonalAddressOption>> _fetchAddressOptions() async {
    try {
      final response = await _apiService.fetchAddressOptions();
      final addressOptions = _PersonalAddressOption.parseList(response.data);
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

class _CertificationPersonalInfoArgs {
  const _CertificationPersonalInfoArgs({
    required this.title,
    required this.payloadMap,
  });

  factory _CertificationPersonalInfoArgs.from(Object? arguments) {
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    return _CertificationPersonalInfoArgs(
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
    return 'Personal information';
  }

  String get productId => (payloadMap['productId'] as String? ?? '').trim();
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
        'assets/certification/certification_personal_progress_step3.png',
        width: 343.w,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class _PersonalInfoField extends StatelessWidget {
  const _PersonalInfoField({required this.field, required this.onTap});

  final _PersonalInfoFieldData field;
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

class _PersonalInfoFieldData {
  _PersonalInfoFieldData({
    required this.label,
    required this.placeholder,
    required this.saveKey,
    required this.fieldType,
    required this.isNumeric,
    required this.options,
    required this.controller,
    required this.selectedValue,
  });

  factory _PersonalInfoFieldData.fromJson(Object? raw) {
    final json = Json(raw);
    final options = _PersonalInfoFieldOption.parseList(json['scabiosa']);
    final initialValue = _stringifyValue(json['disrelished'].rawValue).trim();
    final matchedOption = _matchOption(options, initialValue);
    return _PersonalInfoFieldData(
      label: json['hazinesses'].stringValue.trim(),
      placeholder: json['tissual'].stringValue.trim(),
      saveKey: json['unplait'].stringValue.trim(),
      fieldType: _PersonalInfoFieldType.fromRaw(
        json['dulses'].stringValue.trim(),
      ),
      isNumeric: json['dominances'].intValue == 1,
      options: options,
      controller: TextEditingController(
        text: matchedOption?.label ?? initialValue,
      ),
      selectedValue: matchedOption?.value ?? initialValue,
    );
  }

  final String label;
  final String placeholder;
  final String saveKey;
  final _PersonalInfoFieldType fieldType;
  final bool isNumeric;
  final List<_PersonalInfoFieldOption> options;
  final TextEditingController controller;
  String selectedValue;

  bool get isTextInput => fieldType == _PersonalInfoFieldType.text;

  bool get isCitySelect => fieldType == _PersonalInfoFieldType.citySelect;

  bool get isSelectable => !isTextInput;

  bool get hasValue => currentSubmitValue.isNotEmpty;

  String get currentSubmitValue {
    if (isSelectable) {
      final matched = _matchOption(options, controller.text.trim());
      if (matched != null) {
        return matched.value;
      }
      return selectedValue.trim();
    }
    return controller.text.trim();
  }

  String get displayText {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      return text;
    }
    if (placeholder.isNotEmpty) {
      return placeholder;
    }
    return 'Please enter';
  }

  void selectOption(_PersonalInfoFieldOption option) {
    selectedValue = option.value;
    controller.text = option.label;
  }

  void selectAddress(_PersonalAddressSelection selection) {
    selectedValue = selection.value;
    controller.text = selection.label;
  }

  void dispose() {
    controller.dispose();
  }

  static _PersonalInfoFieldOption? _matchOption(
    List<_PersonalInfoFieldOption> options,
    String rawValue,
  ) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value.trim().toLowerCase() == value ||
          option.label.trim().toLowerCase() == value) {
        return option;
      }
    }
    return null;
  }

  static String _stringifyValue(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    return '$value';
  }
}

enum _PersonalInfoFieldType {
  text,
  enumeration,
  citySelect,
  unknown;

  static _PersonalInfoFieldType fromRaw(String rawType) {
    switch (rawType.trim()) {
      case 'Craniosacral':
        return _PersonalInfoFieldType.text;
      case 'Ataractics':
        return _PersonalInfoFieldType.enumeration;
      case 'RestroomInefficacies':
        return _PersonalInfoFieldType.citySelect;
      default:
        return _PersonalInfoFieldType.unknown;
    }
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

class _PersonalInfoFieldOption {
  const _PersonalInfoFieldOption({
    required this.label,
    required this.value,
    required this.logoUrl,
  });

  final String label;
  final String value;
  final String logoUrl;

  static List<_PersonalInfoFieldOption> parseList(Json json) {
    final result = <_PersonalInfoFieldOption>[];
    if (json.listValue.isNotEmpty) {
      for (final item in json.listValue) {
        final option = _fromDynamic(item);
        if (option != null) {
          result.add(option);
        }
      }
      return result;
    }

    final mapValue = json.mapValue;
    if (mapValue.isNotEmpty) {
      mapValue.forEach((key, value) {
        final option = _normalize(
          label: value is String ? value.trim() : '$value'.trim(),
          value: key.trim(),
        );
        if (option != null) {
          result.add(option);
        }
      });
      return result;
    }

    final raw = json.stringValue.trim();
    if (raw.isEmpty) {
      return result;
    }
    for (final segment in raw.split(',')) {
      final option = _normalize(label: segment.trim(), value: segment.trim());
      if (option != null) {
        result.add(option);
      }
    }
    return result;
  }

  static _PersonalInfoFieldOption? _fromDynamic(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      return _normalize(label: raw.trim(), value: raw.trim());
    }

    final json = Json(raw);
    final label = <String>[
      json['governmental'].stringValue.trim(),
      json['hazinesses'].stringValue.trim(),
      json['reallot'].stringValue.trim(),
      json['label'].stringValue.trim(),
      json['name'].stringValue.trim(),
      json['title'].stringValue.trim(),
      json['text'].stringValue.trim(),
      json['value'].stringValue.trim(),
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final value = <String>[
      json['outcrop'].stringValue.trim(),
      json['value'].stringValue.trim(),
      json['code'].stringValue.trim(),
      json['id'].stringValue.trim(),
      json['key'].stringValue.trim(),
      json['unplait'].stringValue.trim(),
      json['name'].stringValue.trim(),
      json['title'].stringValue.trim(),
      json['label'].stringValue.trim(),
      label,
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');
    return _normalize(
      label: label,
      value: value,
      logoUrl: json['euchromatic'].stringValue.trim(),
    );
  }

  static _PersonalInfoFieldOption? _normalize({
    required String label,
    required String value,
    String logoUrl = '',
  }) {
    final normalizedLabel = label.trim();
    final normalizedValue = value.trim();
    if (normalizedLabel.isEmpty && normalizedValue.isEmpty) {
      return null;
    }
    return _PersonalInfoFieldOption(
      label: normalizedLabel.isNotEmpty ? normalizedLabel : normalizedValue,
      value: normalizedValue.isNotEmpty ? normalizedValue : normalizedLabel,
      logoUrl: logoUrl.trim(),
    );
  }
}

class _PersonalEnumSelectionSheet extends StatefulWidget {
  const _PersonalEnumSelectionSheet({
    required this.options,
    required this.currentValue,
  });

  final List<_PersonalInfoFieldOption> options;
  final String currentValue;

  @override
  State<_PersonalEnumSelectionSheet> createState() =>
      _PersonalEnumSelectionSheetState();
}

class _PersonalEnumSelectionSheetState
    extends State<_PersonalEnumSelectionSheet> {
  late _PersonalInfoFieldOption _selectedOption = _initialSelectedOption();

  _PersonalInfoFieldOption _initialSelectedOption() {
    final normalizedCurrentValue = widget.currentValue.trim().toLowerCase();
    if (normalizedCurrentValue.isEmpty) {
      return widget.options.first;
    }
    return widget.options.firstWhere(
      (option) =>
          option.value.trim().toLowerCase() == normalizedCurrentValue ||
          option.label.trim().toLowerCase() == normalizedCurrentValue,
      orElse: () => widget.options.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableListHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical -
        140.h;
    final maxVisibleOptionsHeight = 326.h;
    final maxListHeight = math.min(
      availableListHeight,
      maxVisibleOptionsHeight,
    );
    return SafeArea(
      top: false,
      child: Padding(
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
                bottom: 21,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: ScreenAdapter.edgeInsetsOnly(top: 21, bottom: 21),
                    child: Container(
                      width: double.infinity,
                      height: 2.h,
                      color: AppColors.certificationUploadDialogDivider,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    return _PersonalEnumOptionRow(
                      option: option,
                      isSelected: option.value == _selectedOption.value,
                      onTap: () => setState(() => _selectedOption = option),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _PersonalEnumActionButton(
                    title: 'Cancel',
                    textColor: AppColors.certificationUploadDialogCancelText,
                    backgroundColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _PersonalEnumActionButton(
                    title: 'Done',
                    textColor: Colors.white,
                    backgroundColor: AppColors.certificationUploadDialogConfirm,
                    fontWeight: FontWeight.w700,
                    onTap: () => Navigator.of(context).pop(_selectedOption),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalEnumOptionRow extends StatelessWidget {
  const _PersonalEnumOptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _PersonalInfoFieldOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: ScreenAdapter.edgeInsetsOnly(left: 11, right: 6),
        child: Row(
          children: [
            if (option.logoUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  option.logoUrl,
                  width: 30.w,
                  height: 30.h,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              SizedBox(width: 15.w),
            ],
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.certificationUploadDialogText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  height: 22 / 18,
                ),
              ),
            ),
            if (isSelected) const _PersonalEnumSelectedIndicator(),
          ],
        ),
      ),
    );
  }
}

class _PersonalEnumSelectedIndicator extends StatelessWidget {
  const _PersonalEnumSelectedIndicator();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/certification/check_icon.png',
      width: 20.w,
      height: 20.h,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.check_circle,
        size: 20.w,
        color: AppColors.certificationUploadDialogConfirm,
      ),
    );
  }
}

class _PersonalEnumActionButton extends StatelessWidget {
  const _PersonalEnumActionButton({
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

class _PersonalAddressSheet extends StatefulWidget {
  const _PersonalAddressSheet({
    required this.title,
    required this.options,
    required this.currentValue,
  });

  final String title;
  final List<_PersonalAddressOption> options;
  final String currentValue;

  @override
  State<_PersonalAddressSheet> createState() => _PersonalAddressSheetState();
}

enum _PersonalAddressLevel { region, province, municipality }

class _PersonalAddressSheetState extends State<_PersonalAddressSheet> {
  int _selectedProvinceIndex = 0;
  int _selectedCityIndex = 0;
  int _selectedDistrictIndex = 0;
  _PersonalAddressLevel _activeLevel = _PersonalAddressLevel.region;
  _PersonalAddressLevel _maxReachedLevel = _PersonalAddressLevel.region;

  @override
  void initState() {
    super.initState();
    _syncInitialSelection();
  }

  void _syncInitialSelection() {
    final parts = widget.currentValue
        .split('-')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty || widget.options.isEmpty) {
      return;
    }
    final provinceIndex = widget.options.indexWhere(
      (option) => option.label == parts.first,
    );
    if (provinceIndex < 0) {
      return;
    }
    _selectedProvinceIndex = provinceIndex;
    final cities = widget.options[provinceIndex].children;
    if (parts.length < 2 || cities.isEmpty) {
      return;
    }
    final cityIndex = cities.indexWhere((option) => option.label == parts[1]);
    if (cityIndex < 0) {
      return;
    }
    _selectedCityIndex = cityIndex;
    final districts = cities[cityIndex].children;
    if (parts.length < 3 || districts.isEmpty) {
      _maxReachedLevel = _PersonalAddressLevel.province;
      return;
    }
    final districtIndex = districts.indexWhere(
      (option) => option.label == parts[2],
    );
    if (districtIndex >= 0) {
      _selectedDistrictIndex = districtIndex;
      _maxReachedLevel = _PersonalAddressLevel.municipality;
      return;
    }
    _maxReachedLevel = _PersonalAddressLevel.province;
  }

  void _handleLevelTap(int index) {
    switch (_activeLevel) {
      case _PersonalAddressLevel.region:
        setState(() {
          _selectedProvinceIndex = index;
          _selectedCityIndex = 0;
          _selectedDistrictIndex = 0;
        });
      case _PersonalAddressLevel.province:
        setState(() {
          _selectedCityIndex = index;
          _selectedDistrictIndex = 0;
        });
      case _PersonalAddressLevel.municipality:
        setState(() => _selectedDistrictIndex = index);
    }
  }

  void _handleDoneTap() {
    switch (_activeLevel) {
      case _PersonalAddressLevel.region:
        setState(() {
          _activeLevel = _PersonalAddressLevel.province;
          _maxReachedLevel = _PersonalAddressLevel.province;
        });
      case _PersonalAddressLevel.province:
        final selectedProvince = widget.options[_selectedProvinceIndex];
        final cities = selectedProvince.children;
        if (cities.isEmpty ||
            cities[math.min(_selectedCityIndex, cities.length - 1)]
                .children
                .isEmpty) {
          Navigator.of(context).pop(_buildSelection());
          return;
        }
        setState(() {
          _activeLevel = _PersonalAddressLevel.municipality;
          _maxReachedLevel = _PersonalAddressLevel.municipality;
        });
      case _PersonalAddressLevel.municipality:
        Navigator.of(context).pop(_buildSelection());
    }
  }

  void _handleSegmentTap(_PersonalAddressLevel level) {
    if (!_canTapLevel(level)) {
      return;
    }
    setState(() {
      switch (level) {
        case _PersonalAddressLevel.region:
          _selectedCityIndex = 0;
          _selectedDistrictIndex = 0;
          _activeLevel = _PersonalAddressLevel.region;
          _maxReachedLevel = _PersonalAddressLevel.region;
        case _PersonalAddressLevel.province:
          _selectedDistrictIndex = 0;
          _activeLevel = _PersonalAddressLevel.province;
          _maxReachedLevel = _PersonalAddressLevel.province;
        case _PersonalAddressLevel.municipality:
          _activeLevel = _PersonalAddressLevel.municipality;
      }
    });
  }

  bool _canTapLevel(_PersonalAddressLevel level) {
    return _levelRank(level) <= _levelRank(_maxReachedLevel);
  }

  int _levelRank(_PersonalAddressLevel level) {
    switch (level) {
      case _PersonalAddressLevel.region:
        return 0;
      case _PersonalAddressLevel.province:
        return 1;
      case _PersonalAddressLevel.municipality:
        return 2;
    }
  }

  String _segmentTitle(_PersonalAddressLevel level) {
    final selectedProvince = widget.options[_selectedProvinceIndex];
    switch (level) {
      case _PersonalAddressLevel.region:
        return _maxReachedLevel == _PersonalAddressLevel.region
            ? 'Region'
            : selectedProvince.label;
      case _PersonalAddressLevel.province:
        if (_maxReachedLevel == _PersonalAddressLevel.region) {
          return 'Province';
        }
        final cities = selectedProvince.children;
        if (cities.isEmpty) {
          return 'Province';
        }
        return cities[math.min(_selectedCityIndex, cities.length - 1)].label;
      case _PersonalAddressLevel.municipality:
        if (_maxReachedLevel != _PersonalAddressLevel.municipality) {
          return 'Municipality';
        }
        final cities = selectedProvince.children;
        if (cities.isEmpty) {
          return 'Municipality';
        }
        final districts =
            cities[math.min(_selectedCityIndex, cities.length - 1)].children;
        if (districts.isEmpty) {
          return 'Municipality';
        }
        return districts[math.min(_selectedDistrictIndex, districts.length - 1)]
            .label;
    }
  }

  _PersonalAddressSelection _buildSelection() {
    final selectedProvince = widget.options[_selectedProvinceIndex];
    final cities = selectedProvince.children;
    if (cities.isEmpty) {
      return _PersonalAddressSelection(
        label: selectedProvince.label,
        value: selectedProvince.label,
      );
    }
    final selectedCity =
        cities[math.min(_selectedCityIndex, cities.length - 1)];
    final districts = selectedCity.children;
    if (districts.isEmpty) {
      final value = '${selectedProvince.label}-${selectedCity.label}';
      return _PersonalAddressSelection(label: value, value: value);
    }
    final selectedDistrict =
        districts[math.min(_selectedDistrictIndex, districts.length - 1)];
    final value =
        '${selectedProvince.label}-${selectedCity.label}-${selectedDistrict.label}';
    return _PersonalAddressSelection(label: value, value: value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvince = widget.options[_selectedProvinceIndex];
    final cities = selectedProvince.children;
    final selectedCity = cities.isEmpty ? null : cities[_selectedCityIndex];
    final districts = selectedCity?.children ?? const <_PersonalAddressNode>[];
    final activeOptions = switch (_activeLevel) {
      _PersonalAddressLevel.region => widget.options,
      _PersonalAddressLevel.province => cities,
      _PersonalAddressLevel.municipality => districts,
    };
    final selectedIndex = switch (_activeLevel) {
      _PersonalAddressLevel.region => _selectedProvinceIndex,
      _PersonalAddressLevel.province => _selectedCityIndex,
      _PersonalAddressLevel.municipality => _selectedDistrictIndex,
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: ScreenAdapter.edgeInsetsOnly(left: 15, right: 15, bottom: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Padding(
                padding: ScreenAdapter.edgeInsetsOnly(
                  left: 9,
                  top: 15,
                  right: 10,
                  bottom: 25,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PersonalAddressSegment(
                      activeLevel: _activeLevel,
                      maxReachedLevel: _maxReachedLevel,
                      regionTitle: _segmentTitle(_PersonalAddressLevel.region),
                      provinceTitle: _segmentTitle(
                        _PersonalAddressLevel.province,
                      ),
                      municipalityTitle: _segmentTitle(
                        _PersonalAddressLevel.municipality,
                      ),
                      onLevelChanged: _handleSegmentTap,
                    ),
                    SizedBox(height: 31.h),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 284.h),
                      child: _PersonalAddressColumn(
                        options: activeOptions,
                        selectedIndex: selectedIndex,
                        onTap: _handleLevelTap,
                        showSelectedIndicator: true,
                        dividerColor:
                            AppColors.certificationUploadDialogDivider,
                        textColor: AppColors.certificationUploadDialogText,
                        selectedFontWeight: FontWeight.w400,
                        itemPadding: ScreenAdapter.edgeInsetsOnly(
                          left: 29,
                          right: 29,
                          top: 24,
                          bottom: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _PersonalEnumActionButton(
                    title: 'Cancel',
                    textColor: AppColors.certificationUploadDialogCancelText,
                    backgroundColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: _PersonalEnumActionButton(
                    title: 'Done',
                    textColor: Colors.white,
                    backgroundColor: AppColors.certificationUploadDialogConfirm,
                    fontWeight: FontWeight.w700,
                    onTap: _handleDoneTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalAddressSegment extends StatelessWidget {
  const _PersonalAddressSegment({
    required this.activeLevel,
    required this.maxReachedLevel,
    required this.regionTitle,
    required this.provinceTitle,
    required this.municipalityTitle,
    required this.onLevelChanged,
  });

  final _PersonalAddressLevel activeLevel;
  final _PersonalAddressLevel maxReachedLevel;
  final String regionTitle;
  final String provinceTitle;
  final String municipalityTitle;
  final ValueChanged<_PersonalAddressLevel> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PersonalAddressSegmentItem(
              itemKey: const Key('personal_address_segment_region'),
              title: regionTitle,
              isActive: activeLevel == _PersonalAddressLevel.region,
              isLeading: true,
              isEnabled:
                  _levelRank(_PersonalAddressLevel.region) <=
                  _levelRank(maxReachedLevel),
              onTap: () => onLevelChanged(_PersonalAddressLevel.region),
            ),
          ),
          Container(width: 1.w, color: const Color(0xFFF0F0F0)),
          Expanded(
            child: _PersonalAddressSegmentItem(
              itemKey: const Key('personal_address_segment_province'),
              title: provinceTitle,
              isActive: activeLevel == _PersonalAddressLevel.province,
              isEnabled:
                  _levelRank(_PersonalAddressLevel.province) <=
                  _levelRank(maxReachedLevel),
              onTap: () => onLevelChanged(_PersonalAddressLevel.province),
            ),
          ),
          Container(width: 1.w, color: const Color(0xFFF0F0F0)),
          Expanded(
            child: _PersonalAddressSegmentItem(
              itemKey: const Key('personal_address_segment_municipality'),
              title: municipalityTitle,
              isActive: activeLevel == _PersonalAddressLevel.municipality,
              isTrailing: true,
              isEnabled:
                  _levelRank(_PersonalAddressLevel.municipality) <=
                  _levelRank(maxReachedLevel),
              onTap: () => onLevelChanged(_PersonalAddressLevel.municipality),
            ),
          ),
        ],
      ),
    );
  }

  int _levelRank(_PersonalAddressLevel level) {
    switch (level) {
      case _PersonalAddressLevel.region:
        return 0;
      case _PersonalAddressLevel.province:
        return 1;
      case _PersonalAddressLevel.municipality:
        return 2;
    }
  }
}

class _PersonalAddressSegmentItem extends StatelessWidget {
  const _PersonalAddressSegmentItem({
    this.itemKey,
    required this.title,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
    this.isLeading = false,
    this.isTrailing = false,
  });

  final Key? itemKey;
  final String title;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;
  final bool isLeading;
  final bool isTrailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? onTap : null,
      child: Container(
        key: itemKey,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.certificationUploadDialogConfirm : null,
          borderRadius: BorderRadius.horizontal(
            left: isLeading ? Radius.circular(18.r) : Radius.zero,
            right: isTrailing ? Radius.circular(18.r) : Radius.zero,
          ),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFFC6C6C6),
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            height: 18 / 12,
          ),
        ),
      ),
    );
  }
}

class _PersonalAddressColumn extends StatelessWidget {
  const _PersonalAddressColumn({
    required this.options,
    required this.selectedIndex,
    required this.onTap,
    this.showSelectedIndicator = false,
    this.dividerColor = AppColors.certificationDivider,
    this.textColor = AppColors.certificationTextPrimary,
    this.selectedFontWeight = FontWeight.w700,
    this.itemPadding,
  });

  final List<_PersonalAddressNode> options;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool showSelectedIndicator;
  final Color dividerColor;
  final Color textColor;
  final FontWeight selectedFontWeight;
  final EdgeInsetsGeometry? itemPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: dividerColor),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = index == selectedIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          child: Padding(
            padding:
                itemPadding ??
                ScreenAdapter.edgeInsetsOnly(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 14,
                ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18.sp,
                      fontWeight: isSelected
                          ? selectedFontWeight
                          : FontWeight.w400,
                      height: 22 / 18,
                    ),
                  ),
                ),
                if (showSelectedIndicator && isSelected)
                  const _PersonalEnumSelectedIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonalAddressNode {
  const _PersonalAddressNode({
    required this.addressId,
    required this.label,
    required this.children,
  });

  final String addressId;
  final String label;
  final List<_PersonalAddressNode> children;

  factory _PersonalAddressNode.fromJson(Json json) {
    return _PersonalAddressNode(
      addressId: json['isolines'].stringValue.trim(),
      label: json['governmental'].stringValue.trim(),
      children: json['keelboat'].listValue
          .map((item) => _PersonalAddressNode.fromJson(Json(item)))
          .where((item) => item.label.isNotEmpty)
          .toList(),
    );
  }
}

class _PersonalAddressOption extends _PersonalAddressNode {
  const _PersonalAddressOption({
    required super.label,
    required super.children,
    required super.addressId,
  });

  static List<_PersonalAddressOption> parseList(Json json) {
    final items = json['keelboat'].listValue;
    return items
        .map((item) => _PersonalAddressOption.fromJson(Json(item)))
        .where((item) => item.label.isNotEmpty && item.children.isNotEmpty)
        .toList();
  }

  factory _PersonalAddressOption.fromJson(Json json) {
    final node = _PersonalAddressNode.fromJson(json);
    return _PersonalAddressOption(
      label: node.label,
      children: node.children,
      addressId: node.addressId,
    );
  }
}

class _PersonalAddressSelection {
  const _PersonalAddressSelection({required this.label, required this.value});

  final String label;
  final String value;
}
