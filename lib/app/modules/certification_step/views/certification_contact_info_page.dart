import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';

import '../../../core/json/json.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/certification_upload_hint_banner.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import '../models/certification_personal_info_args.dart';
import '../models/personal_info_field_option.dart';
import 'widgets/enum_selection_sheet.dart';

typedef ContactInfoProductDetailFlowRunner =
    Future<void> Function(String productId);

class CertificationContactInfoPage extends StatefulWidget {
  const CertificationContactInfoPage({
    super.key,
    this.apiService,
    this.productDetailFlowRunner =
        ApiNavigationHelper.fetchProductDetailByProductId,
    this.contactPicker,
  });

  final ApiService? apiService;
  final ContactInfoProductDetailFlowRunner productDetailFlowRunner;
  final FlutterNativeContactPicker? contactPicker;

  @override
  State<CertificationContactInfoPage> createState() =>
      _CertificationContactInfoPageState();
}

class _CertificationContactInfoPageState
    extends State<CertificationContactInfoPage> {
  late final ApiService _apiService =
      widget.apiService ?? Get.find<ApiService>();
  late final CertificationPersonalInfoArgs _pageArgs =
      CertificationPersonalInfoArgs.from(Get.arguments);
  late final FlutterNativeContactPicker _contactPicker =
      widget.contactPicker ?? FlutterNativeContactPicker();
  List<_ContactGroupData> _groups = const <_ContactGroupData>[];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  String get _displayTitle {
    if (_pageArgs.title.isNotEmpty) {
      return _pageArgs.title;
    }
    return 'Contact information';
  }

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  @override
  void dispose() {
    for (final group in _groups) {
      group.dispose();
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
            AppPageHeader(title: _displayTitle),
            SizedBox(height: 16.h),
            const CertificationUploadHintBanner(
              scabiosaFieldKey: 'wolframite',
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
      bottomNavigationBar: _ContactInfoSubmitButton(
        isSubmitting: _isSubmitting,
        onTap: _isSubmitting ? null : _submitContactInfo,
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
                onTap: _loadContactInfo,
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
        const _ContactInfoProgress(),
        SizedBox(height: 23.h),
        for (var index = 0; index < _groups.length; index++) ...[
          _ContactInfoGroup(
            group: _groups[index],
            onRelationshipTap: () => _handleRelationshipTap(_groups[index]),
            onContactTap: () => _handleContactTap(_groups[index]),
          ),
          if (index != _groups.length - 1) SizedBox(height: 25.h),
        ],
      ],
    );
  }

  Future<void> _loadContactInfo() async {
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
      final response = await _apiService.fetchContactInfo({
        'cohabiter': productId,
      });
      final groups = _parseGroups(response.data);
      if (!mounted) {
        for (final group in groups) {
          group.dispose();
        }
        return;
      }
      _replaceGroups(groups);
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

  List<_ContactGroupData> _parseGroups(Json json) {
    final groupList = json['protyles']['keelboat'].listValue;

    return groupList.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final groupJson = Json(item);

      return _ContactGroupData(
        groupKey: groupJson['resiliencies'].stringValue.trim(),
        title: 'Relationship with Emergency Contacts - ${index + 1}',
        relationshipOptions: PersonalInfoFieldOption.parseList(
          groupJson['mycetomatous'],
        ),
        selectedRelationshipValue: groupJson['wiglet'].stringValue.trim(),
        contactName: groupJson['governmental'].stringValue.trim(),
        contactPhone: groupJson['rucking'].stringValue.trim(),
      );
    }).toList();
  }

  void _replaceGroups(List<_ContactGroupData> nextGroups) {
    for (final group in _groups) {
      group.dispose();
    }
    _groups = nextGroups;
  }

  Future<void> _handleRelationshipTap(_ContactGroupData group) async {
    if (group.relationshipOptions.isEmpty) {
      return;
    }
    final selectedOption = await showModalBottomSheet<PersonalInfoFieldOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.certificationUploadDialogBarrier,
      builder: (sheetContext) {
        return EnumSelectionSheet(
          options: group.relationshipOptions,
          currentValue: group.selectedRelationshipValue,
        );
      },
    );
    if (selectedOption == null || !mounted) {
      return;
    }
    setState(() {
      group.selectedRelationshipValue = selectedOption.value;
    });
  }

  Future<void> _handleContactTap(_ContactGroupData group) async {
    Contact? contact;
    try {
      contact = await _contactPicker.selectContact();
    } catch (error) {
      if (!mounted) {
        return;
      }
      EasyLoading.showToast(NetworkErrorMapper.map(error));
      return;
    }

    if (!mounted || contact == null) {
      return;
    }

    final name = (contact.fullName ?? '').trim();
    final phone = _pickPrimaryPhone(contact);
    if (name.isEmpty && phone.isEmpty) {
      return;
    }

    setState(() {
      if (name.isNotEmpty) {
        group.contactName = name;
      }
      if (phone.isNotEmpty) {
        group.contactPhone = phone;
      }
    });
  }

  String _pickPrimaryPhone(Contact contact) {
    final selected = (contact.selectedPhoneNumber ?? '').trim();
    if (selected.isNotEmpty) {
      return selected;
    }
    final numbers = contact.phoneNumbers;
    if (numbers == null) {
      return '';
    }
    for (final item in numbers) {
      final normalized = item.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  Future<void> _submitContactInfo() async {
    final productId = _pageArgs.productId;
    if (productId.isEmpty) {
      return;
    }

    final contacts = _groups.map((group) => group.toSubmitJson()).toList();
    final body = <String, dynamic>{
      'cohabiter': productId,
      'rekeys': Json(contacts).rawString(),
    };

    setState(() => _isSubmitting = true);
    try {
      EasyLoading.show();
      await _apiService.saveContactInfo(body);
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

class _ContactGroupData {
  _ContactGroupData({
    required this.groupKey,
    required this.title,
    required this.relationshipOptions,
    required this.selectedRelationshipValue,
    required this.contactName,
    required this.contactPhone,
  });

  final String groupKey;
  final String title;
  final List<PersonalInfoFieldOption> relationshipOptions;
  String selectedRelationshipValue;
  String contactName;
  String contactPhone;

  String get relationshipDisplayText {
    PersonalInfoFieldOption? matched;
    for (final option in relationshipOptions) {
      final value = selectedRelationshipValue.trim().toLowerCase();
      if (option.value.trim().toLowerCase() == value ||
          option.label.trim().toLowerCase() == value) {
        matched = option;
        break;
      }
    }
    if (matched != null) {
      return matched.label;
    }
    return 'Please select';
  }

  bool get hasRelationshipValue => selectedRelationshipValue.trim().isNotEmpty;

  void dispose() {}

  Map<String, dynamic> toSubmitJson() {
    return <String, dynamic>{
      'resiliencies': groupKey,
      'wiglet': selectedRelationshipValue.trim(),
      'governmental': contactName.trim(),
      'rucking': contactPhone.trim(),
    };
  }
}

class _ContactInfoProgress extends StatelessWidget {
  const _ContactInfoProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/certification/certification_personal_progress_step3.png',
        key: const Key('certification_contact_info_progress_image'),
        width: 343.w,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class _ContactInfoGroup extends StatelessWidget {
  const _ContactInfoGroup({
    required this.group,
    required this.onRelationshipTap,
    required this.onContactTap,
  });

  final _ContactGroupData group;
  final VoidCallback onRelationshipTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final name = group.contactName.trim();
    final phone = group.contactPhone.trim();
    const contactHint = 'Please select contact';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: TextStyle(
            color: AppColors.certificationUploadDialogText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            height: 17 / 14,
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          'Relationship',
          style: TextStyle(
            color: AppColors.certificationUploadSuccessLabel,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 14 / 12,
          ),
        ),
        SizedBox(height: 7.h),
        GestureDetector(
          key: Key(
            'certification_contact_info_group_${group.groupKey}_relationship_selector',
          ),
          behavior: HitTestBehavior.opaque,
          onTap: onRelationshipTap,
          child: Container(
            key: Key(
              'certification_contact_info_group_${group.groupKey}_relationship',
            ),
            height: 40.h,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: ScreenAdapter.edgeInsetsOnly(left: 12, right: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.certificationUploadSuccessInputBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.relationshipDisplayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: group.hasRelationshipValue
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
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Contact information',
          style: TextStyle(
            color: AppColors.certificationUploadSuccessLabel,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 14 / 12,
          ),
        ),
        SizedBox(height: 7.h),
        GestureDetector(
          key: Key(
            'certification_contact_info_group_${group.groupKey}_contact_card',
          ),
          behavior: HitTestBehavior.opaque,
          onTap: onContactTap,
          child: Container(
            width: double.infinity,
            padding: ScreenAdapter.edgeInsetsOnly(
              left: 12,
              top: 13,
              right: 12,
              bottom: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.certificationUploadSuccessInputBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : contactHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: name.isNotEmpty
                              ? AppColors.certificationUploadDialogText
                              : AppColors.certificationUploadSuccessLabel,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          height: 17 / 14,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.certificationUploadDialogText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          height: 17 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Image.asset(
                  'assets/certification/contact_picker_icon.png',
                  width: 16.w,
                  height: 20.h,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.contacts_outlined,
                    size: 20.w,
                    color: AppColors.certificationUploadSuccessButton,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactInfoSubmitButton extends StatelessWidget {
  const _ContactInfoSubmitButton({
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
