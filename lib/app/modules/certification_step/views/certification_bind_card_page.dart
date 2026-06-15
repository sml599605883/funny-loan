import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import '../models/bind_card_info.dart';
import '../models/personal_info_field_option.dart';
import 'widgets/enum_selection_sheet.dart';

typedef BindCardProductDetailFlowRunner =
    Future<void> Function(String productId);

class CertificationBindCardPage extends StatefulWidget {
  const CertificationBindCardPage({
    super.key,
    this.apiService,
    this.productDetailFlowRunner =
        ApiNavigationHelper.fetchProductDetailByProductId,
  });

  final ApiService? apiService;
  final BindCardProductDetailFlowRunner productDetailFlowRunner;

  @override
  State<CertificationBindCardPage> createState() =>
      _CertificationBindCardPageState();
}

class _CertificationBindCardPageState extends State<CertificationBindCardPage> {
  static const Map<String, String> _submitKeyMapping = <String, String>{
    'channelCode': 'pinder',
    'firstName': 'gowans',
    'middleName': 'sunk',
    'lastName': 'bookstores',
    'cardNo': 'hoppings',
    'confirmCardNo': 'copromoter',
  };

  late final ApiService _apiService =
      widget.apiService ?? Get.find<ApiService>();
  late final _BindCardPageArgs _pageArgs = _BindCardPageArgs.from(
    Get.arguments,
  );
  List<BindCardFieldData> _fields = const <BindCardFieldData>[];
  List<BindCardGroupData> _groups = const <BindCardGroupData>[];
  BindCardGroupData? _selectedGroup;
  String _topHintText = '';
  String _bottomHintText = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  final Map<BindCardFieldData, FocusNode> _textFieldFocusNodes =
      <BindCardFieldData, FocusNode>{};
  final Set<BindCardFieldData> _dismissedSuggestionFields =
      <BindCardFieldData>{};
  BindCardFieldData? _activeSuggestionField;

  @override
  void initState() {
    super.initState();
    _loadBindCardInfo();
  }

  @override
  void dispose() {
    _disposeFocusNodes();
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
            _BindCardHeader(title: _pageArgs.displayTitle),
            SizedBox(height: 16.h),
            CertificationUploadHintBanner(text: _topHintText),
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
      bottomNavigationBar: _BindCardFooter(
        noteText: _bottomHintText,
        isSubmitting: _isSubmitting,
        onTap: _isSubmitting ? null : _submitBindCard,
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
                onTap: _loadBindCardInfo,
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
        if (_groups.isNotEmpty) const _BindCardProgress(),
        if (_groups.isNotEmpty) SizedBox(height: 19.h),
        if (_groups.isNotEmpty)
          _BindCardMethodTabs(
            groups: _groups,
            selectedType: _selectedGroup?.type,
            onTap: _handleGroupTap,
          ),
        if (_groups.isNotEmpty) SizedBox(height: 23.h),
        for (var index = 0; index < _fields.length; index++) ...[
          _BindCardField(
            field: _fields[index],
            onTap: () => _handleFieldTap(_fields[index]),
            focusNode: _textFieldFocusNodes[_fields[index]],
            showSuggestionBubble: identical(
              _activeSuggestionField,
              _fields[index],
            ),
            onSuggestionTap: _applySuggestions,
            onSuggestionClose: _dismissActiveSuggestion,
          ),
          if (index != _fields.length - 1) SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Future<void> _loadBindCardInfo() async {
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
      final response = await _apiService.fetchBindCardInfo(<String, dynamic>{
        'cohabiter': productId,
      });
      final bindCardInfo = BindCardInfo.fromJson(response.raw);
      if (!mounted) {
        bindCardInfo.dispose();
        return;
      }
      _replaceFields(bindCardInfo.fields);
      setState(() {
        _groups = bindCardInfo.groups;
        _selectedGroup = bindCardInfo.selectedGroup;
        _topHintText = bindCardInfo.topHintText;
        _bottomHintText = bindCardInfo.bottomHintText;
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

  void _replaceFields(List<BindCardFieldData> nextFields) {
    _disposeFocusNodes();
    for (final field in _fields) {
      field.dispose();
    }
    _fields = nextFields;
    for (final field in _fields) {
      if (field.isSelectable) {
        continue;
      }
      final focusNode = FocusNode();
      focusNode.addListener(_updateActiveSuggestionField);
      field.controller.addListener(_updateActiveSuggestionField);
      _textFieldFocusNodes[field] = focusNode;
    }
    _updateActiveSuggestionField();
  }

  Future<void> _handleFieldTap(BindCardFieldData field) async {
    if (!field.isSelectable || field.options.isEmpty) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
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

  void _handleGroupTap(BindCardGroupData group) {
    if (_selectedGroup?.type == group.type) {
      return;
    }
    _replaceFields(group.copyFields());
    setState(() {
      _selectedGroup = group;
    });
  }

  void _updateActiveSuggestionField() {
    if (!mounted) {
      return;
    }
    for (final field in _fields) {
      if (field.controller.text.trim().isNotEmpty) {
        _dismissedSuggestionFields.remove(field);
      }
    }
    BindCardFieldData? nextField;
    for (final field in _fields) {
      final focusNode = _textFieldFocusNodes[field];
      if (focusNode == null || !focusNode.hasFocus) {
        continue;
      }
      if (field.controller.text.trim().isNotEmpty) {
        continue;
      }
      if (field.suggestedValue.trim().isEmpty) {
        continue;
      }
      if (_dismissedSuggestionFields.contains(field)) {
        continue;
      }
      nextField = field;
      break;
    }
    if (identical(_activeSuggestionField, nextField)) {
      return;
    }
    setState(() {
      _activeSuggestionField = nextField;
    });
  }

  void _dismissActiveSuggestion() {
    final field = _activeSuggestionField;
    if (field == null) {
      return;
    }
    setState(() {
      _dismissedSuggestionFields.add(field);
      _activeSuggestionField = null;
    });
  }

  void _applySuggestions() {
    FocusScope.of(context).unfocus();
    for (final field in _fields) {
      if (field.isSelectable) {
        continue;
      }
      if (field.controller.text.trim().isNotEmpty) {
        continue;
      }
      final suggestion = field.suggestedValue.trim();
      if (suggestion.isEmpty) {
        continue;
      }
      field.controller.text = suggestion;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSuggestionField = null;
    });
  }

  void _disposeFocusNodes() {
    for (final focusNode in _textFieldFocusNodes.values) {
      focusNode.dispose();
    }
    _textFieldFocusNodes.clear();
    _dismissedSuggestionFields.clear();
    _activeSuggestionField = null;
  }

  Future<void> _submitBindCard() async {
    final productId = _pageArgs.productId;
    final selectedGroup = _selectedGroup;
    if (productId.isEmpty || selectedGroup == null) {
      return;
    }

    for (final field in _fields) {
      if (field.isRequired && field.currentSubmitValue.isEmpty) {
        EasyLoading.showToast(
          field.placeholder.isNotEmpty
              ? field.placeholder
              : 'Please complete ${field.label}',
        );
        return;
      }
    }

    final accountField = _fieldForKey('cardNo');
    final confirmAccountField = _fieldForKey('confirmCardNo');
    if (accountField != null &&
        confirmAccountField != null &&
        accountField.currentSubmitValue !=
            confirmAccountField.currentSubmitValue) {
      EasyLoading.showToast('The two account entries do not match');
      return;
    }

    final body = <String, dynamic>{
      'cohabiter': productId,
      'impotencies': selectedGroup.type,
    };
    for (final field in _fields) {
      final submitKey = _submitKeyMapping[field.saveKey] ?? field.saveKey;
      body[submitKey] = field.currentSubmitValue;
    }

    setState(() => _isSubmitting = true);
    try {
      EasyLoading.show();
      await _apiService.submitBindCard(body: body);
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

  BindCardFieldData? _fieldForKey(String saveKey) {
    for (final field in _fields) {
      if (field.saveKey == saveKey) {
        return field;
      }
    }
    return null;
  }
}

class _BindCardPageArgs {
  const _BindCardPageArgs({
    required this.title,
    required this.productId,
    required this.routeKey,
  });

  factory _BindCardPageArgs.from(Object? arguments) {
    final routeArguments = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map
        ? Map<String, dynamic>.from(payload)
        : const <String, dynamic>{};
    return _BindCardPageArgs(
      title: (payloadMap['nextStepTitle'] as String? ?? '').trim(),
      productId: (payloadMap['productId'] as String? ?? '').trim(),
      routeKey: (routeArguments['routeKey'] as String? ?? 'bank').trim(),
    );
  }

  final String title;
  final String productId;
  final String routeKey;

  String get displayTitle => title.isNotEmpty ? title : 'Bind bank card';
}

class _BindCardHeader extends StatelessWidget {
  const _BindCardHeader({required this.title});

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

class _BindCardMethodTabs extends StatelessWidget {
  const _BindCardMethodTabs({
    required this.groups,
    required this.selectedType,
    required this.onTap,
  });

  final List<BindCardGroupData> groups;
  final int? selectedType;
  final ValueChanged<BindCardGroupData> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 38.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          for (final group in groups)
            Expanded(
              child: GestureDetector(
                key: Key('certification_bind_card_tab_${group.type}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(group),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    decoration: BoxDecoration(
                      color: group.type == selectedType
                          ? AppColors.certificationUploadDialogConfirm
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      group.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: group.type == selectedType
                            ? Colors.white
                            : AppColors.certificationUploadSuccessLabel,
                        fontSize: 12.sp,
                        fontWeight: group.type == selectedType
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BindCardField extends StatelessWidget {
  const _BindCardField({
    required this.field,
    required this.onTap,
    required this.focusNode,
    required this.showSuggestionBubble,
    required this.onSuggestionTap,
    required this.onSuggestionClose,
  });

  final BindCardFieldData field;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool showSuggestionBubble;
  final VoidCallback onSuggestionTap;
  final VoidCallback onSuggestionClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
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
                key: Key('certification_bind_card_${field.saveKey}_selector'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: _BindCardFieldContainer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.displayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: field.currentSubmitValue.isNotEmpty
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
              _BindCardFieldContainer(
                child: TextField(
                  key: Key('certification_bind_card_${field.saveKey}_input'),
                  controller: field.controller,
                  focusNode: focusNode,
                  keyboardType: field.saveKey.contains('cardNo')
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: field.placeholder,
                    hintStyle: TextStyle(
                      color: AppColors.certificationUploadSuccessLabel,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
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
        ),
        if (!field.isSelectable && showSuggestionBubble)
          Positioned(
            top: 0,
            right: 25.w,
            child: _BindCardSuggestionBubble(
              text: field.suggestedValue,
              onTap: onSuggestionTap,
              onClose: onSuggestionClose,
            ),
          ),
      ],
    );
  }
}

class _BindCardSuggestionBubble extends StatelessWidget {
  const _BindCardSuggestionBubble({
    required this.text,
    required this.onTap,
    required this.onClose,
  });

  static const _backgroundAsset =
      'assets/certification/bind_card_suggestion_bubble_bg.png';
  static const _iconAsset =
      'assets/certification/bind_card_suggestion_bubble_icon.png';

  final String text;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 44.w),
        child: SizedBox(
          height: 40.h,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _backgroundAsset,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: ScreenAdapter.edgeInsetsOnly(
                  left: 13,
                  top: 9,
                  right: 6,
                  bottom: 18,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      key: const Key(
                        'certification_bind_card_suggestion_bubble',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                      child: Text(
                        text.trim(),
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          height: 12 / 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      key: const Key(
                        'certification_bind_card_suggestion_bubble_close',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      child: SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            _iconAsset,
                            width: 12.w,
                            height: 12.h,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 12.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BindCardProgress extends StatelessWidget {
  const _BindCardProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/certification/certification_personal_progress_step4.png',
        key: const Key('certification_bind_card_progress'),
        width: 314.w,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class _BindCardFieldContainer extends StatelessWidget {
  const _BindCardFieldContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40.h,
      padding: ScreenAdapter.edgeInsetsSymmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.certificationUploadSuccessInputBorder,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _BindCardFooter extends StatelessWidget {
  const _BindCardFooter({
    required this.noteText,
    required this.isSubmitting,
    required this.onTap,
  });

  final String noteText;
  final bool isSubmitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEDEDED),
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 20,
        top: 14,
        right: 20,
        bottom: 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              noteText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.certificationUploadDialogConfirm,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                key: const Key('certification_bind_card_submit_button'),
                height: 50.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSubmitting
                      ? AppColors.loginButtonDisabled
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
          ],
        ),
      ),
    );
  }
}
