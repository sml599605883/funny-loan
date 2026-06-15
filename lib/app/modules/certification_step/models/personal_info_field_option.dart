import '../../../core/json/json.dart';

class PersonalInfoFieldOption {
  const PersonalInfoFieldOption({
    required this.label,
    required this.value,
    this.logoUrl = '',
    this.isUnderMaintenance = false,
    this.maintenanceText = '',
  });

  final String label;
  final String value;
  final String logoUrl;
  final bool isUnderMaintenance;
  final String maintenanceText;

  static List<PersonalInfoFieldOption> parseList(Json json) {
    final result = <PersonalInfoFieldOption>[];
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

  static PersonalInfoFieldOption? _fromDynamic(Object? raw) {
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
      isUnderMaintenance: json['fleshed'].intValue == 1,
      maintenanceText: json['cantilenas'].stringValue.trim(),
    );
  }

  static PersonalInfoFieldOption? _normalize({
    required String label,
    required String value,
    String logoUrl = '',
    bool isUnderMaintenance = false,
    String maintenanceText = '',
  }) {
    final normalizedLabel = label.trim();
    final normalizedValue = value.trim();
    if (normalizedLabel.isEmpty && normalizedValue.isEmpty) {
      return null;
    }
    return PersonalInfoFieldOption(
      label: normalizedLabel.isNotEmpty ? normalizedLabel : normalizedValue,
      value: normalizedValue.isNotEmpty ? normalizedValue : normalizedLabel,
      logoUrl: logoUrl.trim(),
      isUnderMaintenance: isUnderMaintenance,
      maintenanceText: maintenanceText.trim(),
    );
  }
}
