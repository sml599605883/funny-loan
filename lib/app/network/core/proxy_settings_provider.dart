import 'package:flutter/services.dart';

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

abstract class ProxySettingsProvider {
  static const MethodChannel _channel = MethodChannel(
    'funny_loan/network_proxy',
  );

  static Future<ProxySettings?> getSystemProxy() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getSystemProxy',
    );
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
}
