import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'api/api_service.dart';
import 'client/network_client.dart';
import 'config/network_bootstrapper.dart';
import 'config/network_config.dart';
import 'core/auth_expiry_guard.dart';
import 'core/common_params_provider.dart';
import 'core/proxy_settings_provider.dart';
import 'core/response_parser.dart';
import 'debug/network_proxy_manager.dart';
import 'utils/crypto_util.dart';

class NetworkModule {
  NetworkModule._({
    required this.client,
    required this.apiService,
    required this.config,
    required this.state,
  });

  final NetworkClient client;
  final ApiService apiService;
  final NetworkConfig config;
  final MutableNetworkState state;

  static Future<NetworkModule> create(NetworkConfig config) async {
    String? proxyHost;
    int? proxyPort;
    if (!kReleaseMode) {
      final systemProxy =
          NetworkProxyManager.proxySettings ??
          await ProxySettingsProvider.getSystemProxy();
      final envProxyHost = const String.fromEnvironment('PROXY_HOST');
      final envProxyPort = int.tryParse(
        const String.fromEnvironment('PROXY_PORT'),
      );
      proxyHost = envProxyHost.isNotEmpty ? envProxyHost : systemProxy?.host;
      proxyPort = envProxyPort ?? systemProxy?.port;
    }

    final bootstrapDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (_) => true,
      ),
    );
    _configureDebugCapture(
      bootstrapDio,
      proxyHost: proxyHost,
      proxyPort: proxyPort,
    );
    final state = await NetworkBootstrapper(bootstrapDio).bootstrap(config);

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (_) => true,
      ),
    );

    final commonParamsProvider = CommonParamsProvider(config);
    final authExpiryGuard = AuthExpiryGuard(config);
    final responseParser = ResponseParser(
      config: config,
      authExpiryGuard: authExpiryGuard,
    );
    final client = NetworkClient(
      dio: dio,
      config: config,
      state: state,
      commonParamsProvider: commonParamsProvider,
      responseParser: responseParser,
    );
    if (!kReleaseMode) {
      client.enableDebugCapture(
        proxyHost: proxyHost,
        proxyPort: proxyPort,
        badCertificateAllowed: true,
      );
    }
    final cryptoUtil = CryptoUtil(key: config.cryptoKey, iv: config.cryptoIv);

    return NetworkModule._(
      client: client,
      apiService: ApiService(client: client, cryptoUtil: cryptoUtil),
      config: config,
      state: state,
    );
  }

  static void _configureDebugCapture(
    Dio dio, {
    String? proxyHost,
    int? proxyPort,
  }) {
    if (kReleaseMode) {
      return;
    }
    final adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      return;
    }
    adapter.createHttpClient = () {
      final client = HttpClient();
      if (proxyHost != null &&
          proxyHost.isNotEmpty &&
          proxyPort != null &&
          proxyPort > 0) {
        client.findProxy = (_) => 'PROXY $proxyHost:$proxyPort';
      }
      client.badCertificateCallback = (_, _, _) => true;
      return client;
    };
  }
}
