import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';
import '../../models/address_node.dart';
import '../../models/address_option.dart';
import '../../models/address_selection.dart';

class AddressSelectionSheet extends StatefulWidget {
  const AddressSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    this.onSelected,
  });

  final String title;
  final List<AddressOption> options;
  final String currentValue;
  final ValueChanged<AddressSelection>? onSelected;

  @override
  State<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

enum _AddressLevel { region, province, municipality }

class _AddressSelectionSheetState extends State<AddressSelectionSheet> {
  int _selectedProvinceIndex = 0;
  int _selectedCityIndex = 0;
  int _selectedDistrictIndex = 0;
  _AddressLevel _activeLevel = _AddressLevel.region;
  _AddressLevel _maxReachedLevel = _AddressLevel.region;

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
      _maxReachedLevel = _AddressLevel.province;
      return;
    }
    final districtIndex = districts.indexWhere(
      (option) => option.label == parts[2],
    );
    if (districtIndex >= 0) {
      _selectedDistrictIndex = districtIndex;
      _maxReachedLevel = _AddressLevel.municipality;
      return;
    }
    _maxReachedLevel = _AddressLevel.province;
  }

  void _handleLevelTap(int index) {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _selectedProvinceIndex = index;
          _selectedCityIndex = 0;
          _selectedDistrictIndex = 0;
        });
      case _AddressLevel.province:
        setState(() {
          _selectedCityIndex = index;
          _selectedDistrictIndex = 0;
        });
      case _AddressLevel.municipality:
        setState(() => _selectedDistrictIndex = index);
    }
  }

  void _handleDoneTap() {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _activeLevel = _AddressLevel.province;
          _maxReachedLevel = _AddressLevel.province;
        });
      case _AddressLevel.province:
        final selectedProvince = widget.options[_selectedProvinceIndex];
        final cities = selectedProvince.children;
        if (cities.isEmpty ||
            cities[math.min(_selectedCityIndex, cities.length - 1)]
                .children
                .isEmpty) {
          final selection = _buildSelection();
          widget.onSelected?.call(selection);
          Navigator.of(context).pop(selection);
          return;
        }
        setState(() {
          _activeLevel = _AddressLevel.municipality;
          _maxReachedLevel = _AddressLevel.municipality;
        });
      case _AddressLevel.municipality:
        final selection = _buildSelection();
        widget.onSelected?.call(selection);
        Navigator.of(context).pop(selection);
    }
  }

  void _handleSegmentTap(_AddressLevel level) {
    if (!_canTapLevel(level)) {
      return;
    }
    setState(() {
      switch (level) {
        case _AddressLevel.region:
          _selectedCityIndex = 0;
          _selectedDistrictIndex = 0;
          _activeLevel = _AddressLevel.region;
          _maxReachedLevel = _AddressLevel.region;
        case _AddressLevel.province:
          _selectedDistrictIndex = 0;
          _activeLevel = _AddressLevel.province;
          _maxReachedLevel = _AddressLevel.province;
        case _AddressLevel.municipality:
          _activeLevel = _AddressLevel.municipality;
      }
    });
  }

  bool _canTapLevel(_AddressLevel level) {
    return _levelRank(level) <= _levelRank(_maxReachedLevel);
  }

  int _levelRank(_AddressLevel level) {
    switch (level) {
      case _AddressLevel.region:
        return 0;
      case _AddressLevel.province:
        return 1;
      case _AddressLevel.municipality:
        return 2;
    }
  }

  String _segmentTitle(_AddressLevel level) {
    final selectedProvince = widget.options[_selectedProvinceIndex];
    switch (level) {
      case _AddressLevel.region:
        return _maxReachedLevel == _AddressLevel.region
            ? 'Region'
            : selectedProvince.label;
      case _AddressLevel.province:
        if (_maxReachedLevel == _AddressLevel.region) {
          return 'Province';
        }
        final cities = selectedProvince.children;
        if (cities.isEmpty) {
          return 'Province';
        }
        return cities[math.min(_selectedCityIndex, cities.length - 1)].label;
      case _AddressLevel.municipality:
        if (_maxReachedLevel != _AddressLevel.municipality) {
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

  AddressSelection _buildSelection() {
    final selectedProvince = widget.options[_selectedProvinceIndex];
    final cities = selectedProvince.children;
    if (cities.isEmpty) {
      return AddressSelection(
        label: selectedProvince.label,
        value: selectedProvince.label,
      );
    }
    final selectedCity =
        cities[math.min(_selectedCityIndex, cities.length - 1)];
    final districts = selectedCity.children;
    if (districts.isEmpty) {
      final value = '${selectedProvince.label}-${selectedCity.label}';
      return AddressSelection(label: value, value: value);
    }
    final selectedDistrict =
        districts[math.min(_selectedDistrictIndex, districts.length - 1)];
    final value =
        '${selectedProvince.label}-${selectedCity.label}-${selectedDistrict.label}';
    return AddressSelection(label: value, value: value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvince = widget.options[_selectedProvinceIndex];
    final cities = selectedProvince.children;
    final selectedCity = cities.isEmpty ? null : cities[_selectedCityIndex];
    final districts = selectedCity?.children ?? const <AddressNode>[];
    final activeOptions = switch (_activeLevel) {
      _AddressLevel.region => widget.options,
      _AddressLevel.province => cities,
      _AddressLevel.municipality => districts,
    };
    final selectedIndex = switch (_activeLevel) {
      _AddressLevel.region => _selectedProvinceIndex,
      _AddressLevel.province => _selectedCityIndex,
      _AddressLevel.municipality => _selectedDistrictIndex,
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
                    _AddressSegment(
                      activeLevel: _activeLevel,
                      maxReachedLevel: _maxReachedLevel,
                      regionTitle: _segmentTitle(_AddressLevel.region),
                      provinceTitle: _segmentTitle(_AddressLevel.province),
                      municipalityTitle: _segmentTitle(
                        _AddressLevel.municipality,
                      ),
                      onLevelChanged: _handleSegmentTap,
                    ),
                    SizedBox(height: 31.h),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 284.h),
                      child: _AddressColumn(
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
                  child: _AddressActionButton(
                    title: 'Cancel',
                    textColor: AppColors.certificationUploadDialogCancelText,
                    backgroundColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: _AddressActionButton(
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

class _AddressSegment extends StatelessWidget {
  const _AddressSegment({
    required this.activeLevel,
    required this.maxReachedLevel,
    required this.regionTitle,
    required this.provinceTitle,
    required this.municipalityTitle,
    required this.onLevelChanged,
  });

  final _AddressLevel activeLevel;
  final _AddressLevel maxReachedLevel;
  final String regionTitle;
  final String provinceTitle;
  final String municipalityTitle;
  final ValueChanged<_AddressLevel> onLevelChanged;

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
            child: _AddressSegmentItem(
              itemKey: const Key('personal_address_segment_region'),
              title: regionTitle,
              isActive: activeLevel == _AddressLevel.region,
              isLeading: true,
              isEnabled:
                  _levelRank(_AddressLevel.region) <=
                  _levelRank(maxReachedLevel),
              onTap: () => onLevelChanged(_AddressLevel.region),
            ),
          ),
          Container(width: 1.w, color: const Color(0xFFF0F0F0)),
          Expanded(
            child: _AddressSegmentItem(
              itemKey: const Key('personal_address_segment_province'),
              title: provinceTitle,
              isActive: activeLevel == _AddressLevel.province,
              isEnabled:
                  _levelRank(_AddressLevel.province) <=
                  _levelRank(maxReachedLevel),
              onTap: () => onLevelChanged(_AddressLevel.province),
            ),
          ),
          Container(width: 1.w, color: const Color(0xFFF0F0F0)),
          Expanded(
            child: _AddressSegmentItem(
              itemKey: const Key('personal_address_segment_municipality'),
              title: municipalityTitle,
              isActive: activeLevel == _AddressLevel.municipality,
              isTrailing: true,
              isEnabled:
                  _levelRank(_AddressLevel.municipality) <=
                  _levelRank(maxReachedLevel),
              onTap: () => onLevelChanged(_AddressLevel.municipality),
            ),
          ),
        ],
      ),
    );
  }

  int _levelRank(_AddressLevel level) {
    switch (level) {
      case _AddressLevel.region:
        return 0;
      case _AddressLevel.province:
        return 1;
      case _AddressLevel.municipality:
        return 2;
    }
  }
}

class _AddressSegmentItem extends StatelessWidget {
  const _AddressSegmentItem({
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

class _AddressColumn extends StatelessWidget {
  const _AddressColumn({
    required this.options,
    required this.selectedIndex,
    required this.onTap,
    this.showSelectedIndicator = false,
    this.dividerColor = AppColors.certificationDivider,
    this.textColor = AppColors.certificationTextPrimary,
    this.selectedFontWeight = FontWeight.w700,
    this.itemPadding,
  });

  final List<AddressNode> options;
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
                  const _AddressSelectedIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddressSelectedIndicator extends StatelessWidget {
  const _AddressSelectedIndicator();

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

class _AddressActionButton extends StatelessWidget {
  const _AddressActionButton({
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
