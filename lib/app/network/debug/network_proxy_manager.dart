import '../../core/native/native_bridge.dart';

class NetworkProxyManager {
  NetworkProxyManager._();

  static ProxySettings? _proxySettings;

  static ProxySettings? get proxySettings => _proxySettings;

  static Future<void> syncFromSystemProxy() async {
    _proxySettings = await NativeBridge.getSystemProxy();
  }
}
