import '../../../core/json/json.dart';

enum HomePopupType {
  none,
  appUpgrade,
  membershipUpgrade,
  marketing,
  unsupported,
}

class HomePopupData {
  const HomePopupData({
    required this.type,
    this.latestVersion = '',
    this.content = '',
    this.imageUrl = '',
    this.targetUrl = '',
  });

  final HomePopupType type;
  final String latestVersion;
  final String content;
  final String imageUrl;
  final String targetUrl;

  bool get shouldShow {
    return switch (type) {
      HomePopupType.appUpgrade => true,
      HomePopupType.marketing => imageUrl.trim().isNotEmpty,
      _ => false,
    };
  }

  String get displayVersion {
    final normalized = latestVersion.trim();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.toUpperCase().startsWith('V')
        ? normalized
        : 'V$normalized';
  }

  factory HomePopupData.fromJson(Json json) {
    final rawType = json['outcrop'].intValue;
    final dialog = json['fidelismo'];
    return HomePopupData(
      type: _typeFrom(rawType),
      latestVersion: dialog['hysterically'].stringValue.trim(),
      content: dialog['duchesses'].stringValue.trim(),
      imageUrl: dialog['dizzyingly'].stringValue.trim(),
      targetUrl: dialog['sidearms'].stringValue.trim(),
    );
  }

  static HomePopupType _typeFrom(int rawType) {
    return switch (rawType) {
      0 => HomePopupType.none,
      1 => HomePopupType.appUpgrade,
      2 => HomePopupType.membershipUpgrade,
      3 => HomePopupType.marketing,
      _ => HomePopupType.unsupported,
    };
  }
}
