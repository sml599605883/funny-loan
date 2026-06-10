import 'package:flutter/services.dart';

import '../json/json.dart';

class ProxySettings {
  const ProxySettings({
    required this.host,
    required this.port,
    required this.isEnabled,
  });

  final String host;
  final int port;
  final bool isEnabled;

  bool get isValid => isEnabled && host.isNotEmpty && port > 0;
}

class TrustDecisionLivenessResult {
  const TrustDecisionLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.sequenceId,
    required this.livenessId,
    required this.raw,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String sequenceId;
  final String livenessId;
  final Map<String, dynamic> raw;
}

abstract class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'funny_loan/native_bridge',
  );

  static Future<Map<String, dynamic>?> invokeMapMethod(String method) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(method);
    if (result == null) {
      return null;
    }
    return Map<String, dynamic>.from(result);
  }

  static Future<ProxySettings?> getSystemProxy() async {
    final result = await invokeMapMethod('getSystemProxy');
    if (result == null) {
      return null;
    }

    final host = result['host'] as String? ?? '';
    final enabled = result['enabled'] as bool? ?? false;
    final portValue = result['port'];
    final port = switch (portValue) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    final settings = ProxySettings(host: host, port: port, isEnabled: enabled);
    return settings.isValid ? settings : null;
  }

  static Future<TrustDecisionLivenessResult> showTrustDecisionLiveness(
    String unwarned,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'showTrustDecisionLiveness',
        unwarned,
      );
      if (result == null) {
        return const TrustDecisionLivenessResult(
          success: false,
          code: -1,
          message: 'Liveness returned no result',
          image: '',
          sequenceId: '',
          livenessId: '',
          raw: <String, dynamic>{},
        );
      }

      final json = Json(result);
      final rawValue = json['raw'].rawValue;
      return TrustDecisionLivenessResult(
        success: json['success'].boolOrNull ?? false,
        code: json['code'].intOrNull ?? -1,
        message: json['message'].stringValue,
        image: json['image'].stringValue,
        sequenceId: json['sequence_id'].stringValue,
        livenessId: json['liveness_id'].stringValue,
        raw: rawValue is Map ? Map<String, dynamic>.from(rawValue) : const {},
      );
    } on PlatformException catch (error) {
      return TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Failed to start liveness verification',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{
          'code': error.code,
          if (error.details != null) 'details': error.details,
        },
      );
    }
  }
}
