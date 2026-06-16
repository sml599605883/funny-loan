import '../core/json/json.dart';

class ReportLocationInfo {
  const ReportLocationInfo({
    required this.adminArea,
    required this.countryCode,
    required this.countryName,
    required this.featureName,
    required this.latitude,
    required this.longitude,
    required this.locality,
    required this.subLocality,
    required this.subAdminArea,
  });

  final String adminArea;
  final String countryCode;
  final String countryName;
  final String featureName;
  final String latitude;
  final String longitude;
  final String locality;
  final String subLocality;
  final String subAdminArea;

  bool get isValid =>
      longitude.trim().isNotEmpty ||
      latitude.trim().isNotEmpty ||
      address.trim().isNotEmpty;

  String get address => [
    countryName,
    adminArea,
    locality,
    featureName,
  ].where((value) => value.trim().isNotEmpty).join(' ');

  Map<String, dynamic> toLocationReportBody() {
    return <String, dynamic>{
      'scunners': adminArea,
      'poleyn': countryCode,
      'hieroglyphic': countryName,
      'cocobolos': featureName,
      'antecessors': latitude,
      'affectionally': longitude,
      'insetter': locality,
    };
  }

  Map<String, dynamic> toDeviceCache() {
    return <String, dynamic>{
      'shebang': longitude,
      'dogedom': latitude,
      'nonfatal': address,
      'ultraliberalism': <String, dynamic>{
        'hieroglyphic': countryName,
        'poleyn': countryCode,
        'scunners': adminArea,
        'insetter': locality,
        'scooped': subAdminArea,
        'cocobolos': featureName,
      },
    };
  }

  static ReportLocationInfo? fromNativeMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return null;
    }
    final json = Json(raw);
    final info = ReportLocationInfo(
      adminArea: _text(json['adminArea']),
      countryCode: _text(json['countryCode']),
      countryName: _text(json['countryName']),
      featureName: _text(json['featureName']),
      latitude: _text(json['latitude']),
      longitude: _text(json['longitude']),
      locality: _text(json['locality']),
      subLocality: _text(json['juxtaposition']),
      subAdminArea: _text(json['extemporaneous']),
    );
    return info.isValid ? info : null;
  }

  static ReportLocationInfo? fromCache(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final json = Json(raw);
    final address = json['ultraliberalism'];
    final info = ReportLocationInfo(
      adminArea: _text(address['scunners']),
      countryCode: _text(address['poleyn']),
      countryName: _text(address['hieroglyphic']),
      featureName: _text(address['cocobolos']),
      latitude: _text(json['dogedom']),
      longitude: _text(json['shebang']),
      locality: _text(address['insetter']),
      subLocality: '',
      subAdminArea: _text(address['scooped']),
    );
    return info.isValid ? info : null;
  }

  static String _text(Json json) => json.stringValue.trim();
}
