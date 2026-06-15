import 'package:flutter/material.dart';

import '../../../core/json/json.dart';
import 'personal_info_field_option.dart';

class BindCardInfo {
  const BindCardInfo({
    required this.groups,
    required this.selectedGroup,
    required this.fields,
    required this.topHintText,
    required this.bottomHintText,
  });

  factory BindCardInfo.fromJson(Object? raw) {
    final json = Json(raw);
    final groups = json['rekeys']['tingling'].listValue
        .map((item) => BindCardGroupData.fromJson(item))
        .where((group) => group.fields.isNotEmpty)
        .toList();
    final selectedGroup = groups.isNotEmpty ? groups.first : null;
    final copiedFields =
        selectedGroup?.copyFields() ?? const <BindCardFieldData>[];
    return BindCardInfo(
      groups: groups,
      selectedGroup: selectedGroup,
      fields: copiedFields,
      topHintText: json['unchains'].stringValue.trim().isNotEmpty
          ? json['unchains'].stringValue.trim()
          : 'A clear ID photo is the key to lightning-fast approval. Please upload ID front.',
      bottomHintText: json['omitted'].stringValue.trim().isNotEmpty
          ? json['omitted'].stringValue.trim()
          : 'Card number, information — all three must match. One mismatch = money returns.',
    );
  }

  final List<BindCardGroupData> groups;
  final BindCardGroupData? selectedGroup;
  final List<BindCardFieldData> fields;
  final String topHintText;
  final String bottomHintText;

  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
  }
}

class BindCardGroupData {
  const BindCardGroupData({
    required this.label,
    required this.type,
    required this.fields,
  });

  factory BindCardGroupData.fromJson(Object? raw) {
    final json = Json(raw);
    return BindCardGroupData(
      label: json['hazinesses'].stringValue.trim(),
      type: json['outcrop'].intValue,
      fields: json['tingling'].listValue
          .map(BindCardFieldData.fromJson)
          .where((field) => field.label.isNotEmpty && field.saveKey.isNotEmpty)
          .toList(),
    );
  }

  final String label;
  final int type;
  final List<BindCardFieldData> fields;

  List<BindCardFieldData> copyFields() {
    return fields.map((field) => field.copy()).toList();
  }
}

enum BindCardFieldType { text, enumeration }

class BindCardFieldData {
  BindCardFieldData({
    required this.label,
    required this.placeholder,
    required this.saveKey,
    required this.fieldType,
    required this.isRequired,
    required this.options,
    required this.controller,
    required this.selectedValue,
    required this.suggestedValue,
  });

  factory BindCardFieldData.fromJson(Object? raw) {
    final json = Json(raw);
    final options = PersonalInfoFieldOption.parseList(json['scabiosa']);
    final initialLabel = json['triadisms'].stringValue.trim();
    final initialValue = json['disrelished'].stringValue.trim();
    final matchedOption = _matchOption(options, initialValue, initialLabel);
    return BindCardFieldData(
      label: json['hazinesses'].stringValue.trim(),
      placeholder: json['tissual'].stringValue.trim(),
      saveKey: json['unplait'].stringValue.trim(),
      fieldType: _parseFieldType(json['dulses'].stringValue.trim()),
      isRequired: json['centupling'].intValue != 1,
      options: options,
      controller: TextEditingController(
        text: matchedOption?.label ?? initialValue,
      ),
      selectedValue: matchedOption?.value ?? initialValue,
      suggestedValue: initialLabel,
    );
  }

  final String label;
  final String placeholder;
  final String saveKey;
  final BindCardFieldType fieldType;
  final bool isRequired;
  final List<PersonalInfoFieldOption> options;
  final TextEditingController controller;
  String selectedValue;
  final String suggestedValue;

  bool get isSelectable => fieldType == BindCardFieldType.enumeration;

  String get displayText {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      return text;
    }
    if (placeholder.isNotEmpty) {
      return placeholder;
    }
    return 'Please enter ${label.toLowerCase()}';
  }

  String get currentSubmitValue {
    if (!isSelectable) {
      return controller.text.trim();
    }
    final matched = _matchOption(
      options,
      selectedValue,
      controller.text.trim(),
    );
    if (matched != null) {
      return matched.value;
    }
    return selectedValue.trim();
  }

  void selectOption(PersonalInfoFieldOption option) {
    selectedValue = option.value;
    controller.text = option.label;
  }

  BindCardFieldData copy() {
    return BindCardFieldData(
      label: label,
      placeholder: placeholder,
      saveKey: saveKey,
      fieldType: fieldType,
      isRequired: isRequired,
      options: List<PersonalInfoFieldOption>.from(options),
      controller: TextEditingController(text: controller.text),
      selectedValue: selectedValue,
      suggestedValue: suggestedValue,
    );
  }

  void dispose() {
    controller.dispose();
  }

  static PersonalInfoFieldOption? _matchOption(
    List<PersonalInfoFieldOption> options,
    String value,
    String label,
  ) {
    final normalizedValue = value.trim().toLowerCase();
    final normalizedLabel = label.trim().toLowerCase();
    for (final option in options) {
      if (normalizedValue.isNotEmpty &&
          option.value.trim().toLowerCase() == normalizedValue) {
        return option;
      }
      if (normalizedLabel.isNotEmpty &&
          option.label.trim().toLowerCase() == normalizedLabel) {
        return option;
      }
    }
    return null;
  }

  static BindCardFieldType _parseFieldType(String rawType) {
    switch (rawType.trim()) {
      case 'Ataractics':
      case 'enum':
        return BindCardFieldType.enumeration;
      case 'Craniosacral':
      case 'txt':
        return BindCardFieldType.text;
      default:
        return BindCardFieldType.text;
    }
  }
}
