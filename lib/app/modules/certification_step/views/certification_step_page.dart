import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_page_header.dart';
import '../../../core/json/json.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';

class CertificationStepPage extends StatefulWidget {
  const CertificationStepPage({super.key});

  @override
  State<CertificationStepPage> createState() => _CertificationStepPageState();
}

class _CertificationStepPageState extends State<CertificationStepPage> {
  bool _isLoading = false;
  String _errorMessage = '';
  int _selectedGroupIndex = 0;
  List<_IdentityOptionItem> _recommendedOptions = const <_IdentityOptionItem>[];
  List<_IdentityOptionItem> _otherOptions = const <_IdentityOptionItem>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pageArgs = _CertificationStepArgs.from(Get.arguments);
      _initializeIdentityOptions(pageArgs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageArgs = _CertificationStepArgs.from(Get.arguments);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.defaultBackgroundGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: _buildSelectPage(pageArgs),
        ),
      ),
    );
  }

  Widget _buildSelectPage(_CertificationStepArgs pageArgs) {
    final hasOtherOptions = _otherOptions.isNotEmpty;
    final currentOptions = _selectedGroupIndex == 0
        ? _recommendedOptions
        : _otherOptions;

    return SingleChildScrollView(
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 20,
        top: 17,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(title: pageArgs.displayTitle),
          SizedBox(height: 16.h),
          if (hasOtherOptions) ...[
            _CertificationSegmentedControl(
              selectedIndex: _selectedGroupIndex,
              onChanged: (index) {
                if (_selectedGroupIndex == index) {
                  return;
                }
                setState(() {
                  _selectedGroupIndex = index;
                });
              },
            ),
            SizedBox(height: 20.h),
          ],
          Container(
            width: double.infinity,
            padding: ScreenAdapter.edgeInsetsSymmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: _buildSelectBody(pageArgs, currentOptions),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectBody(
    _CertificationStepArgs pageArgs,
    List<_IdentityOptionItem> currentOptions,
  ) {
    if (_isLoading) {
      return SizedBox(
        height: 260.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: ScreenAdapter.edgeInsetsSymmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF3B3B3B), fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => _initializeIdentityOptions(pageArgs),
              child: Container(
                padding: ScreenAdapter.edgeInsetsSymmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A2E),
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
      );
    }

    if (currentOptions.isEmpty) {
      return Padding(
        padding: ScreenAdapter.edgeInsetsSymmetric(vertical: 40),
        child: Text(
          'No identity document options available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: const Color(0xFF3B3B3B), fontSize: 14.sp),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < currentOptions.length; index++) ...[
          _CertificationOptionTile(
            title: currentOptions[index].title,
            onTap: () => _openUploadPage(pageArgs, currentOptions[index]),
          ),
          if (index != currentOptions.length - 1) SizedBox(height: 12.h),
        ],
      ],
    );
  }

  Future<void> _initializeIdentityOptions(_CertificationStepArgs pageArgs) async {
    final payloadJson = Json(pageArgs.payload);
    final productId = payloadJson['productId'].stringValue.trim();
    if (productId.isEmpty || !Get.isRegistered<ApiService>()) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '';
        _isLoading = false;
        _selectedGroupIndex = 0;
        _recommendedOptions = const <_IdentityOptionItem>[];
        _otherOptions = const <_IdentityOptionItem>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await Get.find<ApiService>().fetchIdentityInfo(
        <String, dynamic>{'cohabiter': productId},
      );
      final options = _parseIdentityOptions(response.data['lightnings']);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _selectedGroupIndex = 0;
        _recommendedOptions = options.recommended;
        _otherOptions = options.other;
        _errorMessage = options.recommended.isEmpty && options.other.isEmpty
            ? 'No identity document options available.'
            : '';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _recommendedOptions = const <_IdentityOptionItem>[];
        _otherOptions = const <_IdentityOptionItem>[];
        _errorMessage = NetworkErrorMapper.map(error);
      });
    }
  }

  _IdentityOptions _parseIdentityOptions(Json lightningsJson) {
    final groups = lightningsJson.listValue;
    if (groups.isEmpty) {
      return const _IdentityOptions();
    }

    final firstGroupItems = Json(groups.first).listValue;
    if (firstGroupItems.isEmpty) {
      return _IdentityOptions(
        recommended: groups
            .map((value) => _extractOptionItem(Json(value)))
            .whereType<_IdentityOptionItem>()
            .toList(),
      );
    }

    final recommended = firstGroupItems
        .map((value) => _extractOptionItem(Json(value)))
        .whereType<_IdentityOptionItem>()
        .toList();
    final other = groups
        .skip(1)
        .expand((group) => Json(group).listValue)
        .map((value) => _extractOptionItem(Json(value)))
        .whereType<_IdentityOptionItem>()
        .toList();

    return _IdentityOptions(recommended: recommended, other: other);
  }

  _IdentityOptionItem? _extractOptionItem(Json optionJson) {
    final directString = optionJson.stringValue.trim();
    if (directString.isNotEmpty) {
      return _IdentityOptionItem(title: directString, value: directString);
    }

    final title = optionJson['hazinesses'].stringValue.trim();
    if (title.isEmpty) {
      return null;
    }

    final value = optionJson['sidearms'].stringValue.trim();
    return _IdentityOptionItem(
      title: title,
      value: value.isNotEmpty ? value : title,
    );
  }

  void _openUploadPage(
    _CertificationStepArgs pageArgs,
    _IdentityOptionItem option,
  ) {
    final nextPayload = <String, dynamic>{
      ...Json(pageArgs.payload).mapValue,
      'selectedIdentityTitle': option.title,
      'selectedIdentityValue': option.value,
    };
    NavigationHelper.toCertificationUpload<void>(
      arguments: <String, dynamic>{
        'routeKey': pageArgs.routeKey,
        'payload': nextPayload,
      },
    );
  }
}

class _CertificationStepArgs {
  const _CertificationStepArgs({
    required this.routeKey,
    required this.title,
    required this.payload,
  });

  factory _CertificationStepArgs.from(Object? arguments) {
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    return _CertificationStepArgs(
      routeKey: (routeArguments['routeKey'] as String? ?? '').trim(),
      title: (payloadMap['nextStepTitle'] as String? ?? '').trim(),
      payload: payload,
    );
  }

  final String routeKey;
  final String title;
  final Object? payload;

  String get displayTitle {
    if (title.isNotEmpty) {
      return title;
    }
    return 'Identity verification';
  }
}

class _IdentityOptions {
  const _IdentityOptions({
    this.recommended = const <_IdentityOptionItem>[],
    this.other = const <_IdentityOptionItem>[],
  });

  final List<_IdentityOptionItem> recommended;
  final List<_IdentityOptionItem> other;
}

class _IdentityOptionItem {
  const _IdentityOptionItem({required this.title, required this.value});

  final String title;
  final String value;
}

class _CertificationSegmentedControl extends StatelessWidget {
  const _CertificationSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 36.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CertificationSegmentTab(
              title: 'Recommended ID Type',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _CertificationSegmentTab(
              title: 'Other Options',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationSegmentTab extends StatelessWidget {
  const _CertificationSegmentTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36.h,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF8A2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFAEAEAE),
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CertificationOptionTile extends StatelessWidget {
  const _CertificationOptionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46.h,
        padding: ScreenAdapter.edgeInsetsOnly(left: 10, right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD8E3F5),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              color: const Color(0xFFFF8A2E),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF3B3B3B),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Image.asset(
              'assets/mine/chevron_right.png',
              width: 14.w,
              height: 14.w,
            ),
          ],
        ),
      ),
    );
  }
}
