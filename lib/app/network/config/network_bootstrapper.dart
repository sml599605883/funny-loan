import 'dart:convert';

import 'package:dio/dio.dart';

import 'network_config.dart';

class NetworkBootstrapper {
  NetworkBootstrapper(this._dio);

  final Dio _dio;

  Future<MutableNetworkState> bootstrap(NetworkConfig config) async {
    final state = MutableNetworkState(
      apiBaseUrl: config.defaultApiBaseUrl,
      webBaseUrl: config.defaultWebBaseUrl,
    );

    if (config.defaultApiBaseUrl.isNotEmpty &&
        await _isReachable(config.defaultApiBaseUrl)) {
      return state;
    }

    if (config.remoteConfigUrl.isEmpty) {
      return state;
    }

    try {
      final response = await _dio.get<String>(config.remoteConfigUrl);
      final decoded = _decodeRemoteConfig(response.data ?? '');
      if (decoded['apiBaseUrl'] is String &&
          (decoded['apiBaseUrl'] as String).isNotEmpty) {
        state.apiBaseUrl = decoded['apiBaseUrl'] as String;
      }
      if (decoded['webBaseUrl'] is String &&
          (decoded['webBaseUrl'] as String).isNotEmpty) {
        state.webBaseUrl = decoded['webBaseUrl'] as String;
      }
    } catch (_) {
      return state;
    }

    return state;
  }

  Future<bool> _isReachable(String baseUrl) async {
    try {
      final response = await _dio.getUri(Uri.parse(baseUrl));
      final statusCode = response.statusCode;
      return statusCode != null && statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeRemoteConfig(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const {};
    }

    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      try {
        final decoded = utf8.decode(base64Decode(trimmed));
        return jsonDecode(decoded) as Map<String, dynamic>;
      } catch (_) {
        return const {};
      }
    }
  }
}
