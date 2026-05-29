import '../core/proxy_settings_provider.dart';

class NetworkProxyManager {
  NetworkProxyManager._();

  static ProxySettings? _proxySettings;

  static ProxySettings? get proxySettings => _proxySettings;

  static Future<void> syncFromSystemProxy() async {
    _proxySettings = await ProxySettingsProvider.getSystemProxy();
  }
}
