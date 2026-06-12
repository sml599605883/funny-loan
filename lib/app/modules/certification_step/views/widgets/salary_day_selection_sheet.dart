import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/json/json.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class SalaryDayGroup {
  const SalaryDayGroup({
    required this.label,
    required this.value,
    required this.children,
  });

  final String label;
  final String value;
  final List<SalaryDayOption> children;

  static List<SalaryDayGroup> parseList(Object? raw) {
    final result = <SalaryDayGroup>[];
    for (final item in Json(raw).listValue) {
      final json = Json(item);
      final label = _firstNonEmpty(<String>[
        json['governmental'].stringValue.trim(),
        json['hazinesses'].stringValue.trim(),
        json['reallot'].stringValue.trim(),
        json['label'].stringValue.trim(),
        json['name'].stringValue.trim(),
        json['title'].stringValue.trim(),
        json['text'].stringValue.trim(),
        json['value'].stringValue.trim(),
      ]);
      final value = _firstNonEmpty(<String>[
        json['outcrop'].stringValue.trim(),
        json['value'].stringValue.trim(),
        json['code'].stringValue.trim(),
        json['id'].stringValue.trim(),
        json['key'].stringValue.trim(),
        json['unplait'].stringValue.trim(),
        label,
      ]);
      final children = SalaryDayOption.parseList(
        json['keelboat'].rawValue ?? json['scabiosa'].rawValue,
      );
      if (label.isEmpty || children.isEmpty) {
        continue;
      }
      result.add(
        SalaryDayGroup(
          label: label,
          value: value,
          children: children,
        ),
      );
    }
    return result;
  }
}

class SalaryDayOption {
  const SalaryDayOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static List<SalaryDayOption> parseList(Object? raw) {
    final result = <SalaryDayOption>[];
    for (final item in Json(raw).listValue) {
      final json = Json(item);
      final label = _firstNonEmpty(<String>[
        json['governmental'].stringValue.trim(),
        json['hazinesses'].stringValue.trim(),
        json['reallot'].stringValue.trim(),
        json['label'].stringValue.trim(),
        json['name'].stringValue.trim(),
        json['title'].stringValue.trim(),
        json['text'].stringValue.trim(),
        json['value'].stringValue.trim(),
      ]);
      final value = _firstNonEmpty(<String>[
        json['outcrop'].stringValue.trim(),
        json['value'].stringValue.trim(),
        json['code'].stringValue.trim(),
        json['id'].stringValue.trim(),
        json['key'].stringValue.trim(),
        json['unplait'].stringValue.trim(),
        label,
      ]);
      if (label.isEmpty || value.isEmpty) {
        continue;
      }
      result.add(SalaryDayOption(label: label, value: value));
    }
    return result;
  }
}

class SalaryDaySelection {
  const SalaryDaySelection({
    required this.displayText,
    required this.submitValue,
    required this.groupValue,
  });

  final String displayText;
  final String submitValue;
  final String groupValue;

  static SalaryDaySelection? fromSubmitValue(
    List<SalaryDayGroup> groups,
    String submitValue,
  ) {
    final normalizedValue = submitValue.trim().toLowerCase();
    if (normalizedValue.isEmpty) {
      return null;
    }
    for (final group in groups) {
      for (final child in group.children) {
        if (child.value.trim().toLowerCase() != normalizedValue) {
          continue;
        }
        return SalaryDaySelection(
          displayText: '${group.label}|${child.label}',
          submitValue: child.value,
          groupValue: group.value,
        );
      }
    }
    return null;
  }
}

class SalaryDaySelectionSheet extends StatefulWidget {
  const SalaryDaySelectionSheet({
    super.key,
    required this.options,
    required this.currentGroupValue,
    required this.currentChildValue,
    this.onSelected,
  });

  final List<SalaryDayGroup> options;
  final String currentGroupValue;
  final String currentChildValue;
  final ValueChanged<SalaryDaySelection>? onSelected;

  @override
  State<SalaryDaySelectionSheet> createState() => _SalaryDaySelectionSheetState();
}

enum _SalaryDayLevel { group, child }

class _SalaryDaySelectionSheetState extends State<SalaryDaySelectionSheet> {
  late int _selectedGroupIndex = _initialGroupIndex();
  late int _selectedChildIndex = _initialChildIndex();
  _SalaryDayLevel _activeLevel = _SalaryDayLevel.group;

  int _initialGroupIndex() {
    final normalizedGroupValue = widget.currentGroupValue.trim().toLowerCase();
    final normalizedChildValue = widget.currentChildValue.trim().toLowerCase();
    if (normalizedGroupValue.isNotEmpty) {
      final matchedIndex = widget.options.indexWhere(
        (option) => option.value.trim().toLowerCase() == normalizedGroupValue,
      );
      if (matchedIndex >= 0) {
        return matchedIndex;
      }
    }
    if (normalizedChildValue.isNotEmpty) {
      final matchedIndex = widget.options.indexWhere(
        (option) => option.children.any(
          (child) => child.value.trim().toLowerCase() == normalizedChildValue,
        ),
      );
      if (matchedIndex >= 0) {
        return matchedIndex;
      }
    }
    return 0;
  }

  int _initialChildIndex() {
    final children = widget.options[_selectedGroupIndex].children;
    final normalizedChildValue = widget.currentChildValue.trim().toLowerCase();
    if (normalizedChildValue.isEmpty) {
      return 0;
    }
    final matchedIndex = children.indexWhere(
      (child) => child.value.trim().toLowerCase() == normalizedChildValue,
    );
    return matchedIndex >= 0 ? matchedIndex : 0;
  }

  void _handleDoneTap() {
    if (_activeLevel == _SalaryDayLevel.group) {
      setState(() => _activeLevel = _SalaryDayLevel.child);
      return;
    }
    final group = widget.options[_selectedGroupIndex];
    final child = group.children[_selectedChildIndex];
    final selection = SalaryDaySelection(
      displayText: '${group.label}|${child.label}',
      submitValue: child.value,
      groupValue: group.value,
    );
    widget.onSelected?.call(selection);
    Navigator.of(context).pop(selection);
  }

  void _handleCancelTap() {
    if (_activeLevel == _SalaryDayLevel.child) {
      setState(() => _activeLevel = _SalaryDayLevel.group);
      return;
    }
    Navigator.of(context).pop();
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
    final groups = widget.options;
    final children = groups[_selectedGroupIndex].children;
    final itemCount = _activeLevel == _SalaryDayLevel.group
        ? groups.length
        : children.length;
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
                  itemCount: itemCount,
                  separatorBuilder: (context, index) => Padding(
                    padding: ScreenAdapter.edgeInsetsOnly(top: 21, bottom: 21),
                    child: Container(
                      width: double.infinity,
                      height: 2.h,
                      color: AppColors.certificationUploadDialogDivider,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final title = _activeLevel == _SalaryDayLevel.group
                        ? groups[index].label
                        : children[index].label;
                    final isSelected = _activeLevel == _SalaryDayLevel.group
                        ? index == _selectedGroupIndex
                        : index == _selectedChildIndex;
                    return _SalaryDayOptionRow(
                      title: title,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (_activeLevel == _SalaryDayLevel.group) {
                            _selectedGroupIndex = index;
                            _selectedChildIndex = 0;
                            return;
                          }
                          _selectedChildIndex = index;
                        });
                      },
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
                    onTap: _handleCancelTap,
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

class _SalaryDayOptionRow extends StatelessWidget {
  const _SalaryDayOptionRow({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
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
            Expanded(
              child: Text(
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

String _firstNonEmpty(List<String> values) {
  return values.firstWhere((item) => item.isNotEmpty, orElse: () => '');
}
