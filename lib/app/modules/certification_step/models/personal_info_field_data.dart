import 'package:flutter/material.dart';

import '../../../core/json/json.dart';
import 'address_selection.dart';
import 'personal_info_field_option.dart';
import 'personal_info_field_type.dart';

class PersonalInfoFieldData {
  PersonalInfoFieldData({
    required this.label,
    required this.placeholder,
    required this.saveKey,
    required this.fieldType,
    required this.isNumeric,
    required this.options,
    required this.controller,
    required this.selectedValue,
  });

  factory PersonalInfoFieldData.fromJson(Object? raw) {
    final json = Json(raw);
    final options = PersonalInfoFieldOption.parseList(json['scabiosa']);
    final initialValue = _stringifyValue(json['disrelished'].rawValue).trim();
    final matchedOption = _matchOption(options, initialValue);
    return PersonalInfoFieldData(
      label: json['hazinesses'].stringValue.trim(),
      placeholder: json['tissual'].stringValue.trim(),
      saveKey: json['unplait'].stringValue.trim(),
      fieldType: PersonalInfoFieldType.fromRaw(
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
  final PersonalInfoFieldType fieldType;
  final bool isNumeric;
  final List<PersonalInfoFieldOption> options;
  final TextEditingController controller;
  String selectedValue;

  bool get isTextInput => fieldType == PersonalInfoFieldType.text;

  bool get isCitySelect => fieldType == PersonalInfoFieldType.citySelect;

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

  void selectOption(PersonalInfoFieldOption option) {
    selectedValue = option.value;
    controller.text = option.label;
  }

  void selectAddress(AddressSelection selection) {
    selectedValue = selection.value;
    controller.text = selection.label;
  }

  void dispose() {
    controller.dispose();
  }

  static PersonalInfoFieldOption? _matchOption(
    List<PersonalInfoFieldOption> options,
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
