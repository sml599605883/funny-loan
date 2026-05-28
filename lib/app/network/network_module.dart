import 'package:dio/dio.dart';

import 'api/api_service.dart';
import 'client/network_client.dart';
import 'config/network_bootstrapper.dart';
import 'config/network_config.dart';
import 'core/auth_expiry_guard.dart';
import 'core/common_params_provider.dart';
import 'core/response_parser.dart';
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
    final bootstrapDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (_) => true,
      ),
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
    final cryptoUtil = CryptoUtil(
      key: config.cryptoKey,
      iv: config.cryptoIv,
    );

    return NetworkModule._(
      client: client,
      apiService: ApiService(client: client, cryptoUtil: cryptoUtil),
      config: config,
      state: state,
    );
  }
}
