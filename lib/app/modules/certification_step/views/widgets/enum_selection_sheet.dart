import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';
import '../../models/personal_info_field_option.dart';

class EnumSelectionSheet extends StatefulWidget {
  const EnumSelectionSheet({
    super.key,
    required this.options,
    required this.currentValue,
    this.onSelected,
  });

  final List<PersonalInfoFieldOption> options;
  final String currentValue;
  final ValueChanged<PersonalInfoFieldOption>? onSelected;

  @override
  State<EnumSelectionSheet> createState() => _EnumSelectionSheetState();
}

class _EnumSelectionSheetState extends State<EnumSelectionSheet> {
  late PersonalInfoFieldOption _selectedOption = _initialSelectedOption();

  PersonalInfoFieldOption _initialSelectedOption() {
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

  void _handleDoneTap() {
    widget.onSelected?.call(_selectedOption);
    Navigator.of(context).pop(_selectedOption);
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
                    return _EnumOptionRow(
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
                  child: _SheetActionButton(
                    title: 'Cancel',
                    textColor: AppColors.certificationUploadDialogCancelText,
                    backgroundColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _SheetActionButton(
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

class _EnumOptionRow extends StatelessWidget {
  const _EnumOptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final PersonalInfoFieldOption option;
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
            if (isSelected) const _SheetSelectedIndicator(),
          ],
        ),
      ),
    );
  }
}

class _SheetSelectedIndicator extends StatelessWidget {
  const _SheetSelectedIndicator();

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

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
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
