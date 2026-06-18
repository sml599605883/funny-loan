import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/modules/mine/controllers/mine_controller.dart';
import 'package:funny_loan/app/network/api/api_service.dart';
import 'package:funny_loan/app/network/client/network_client.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/network/core/auth_expiry_guard.dart';
import 'package:funny_loan/app/network/core/common_params_provider.dart';
import 'package:funny_loan/app/network/core/response_parser.dart';
import 'package:funny_loan/app/network/models/network_response.dart';
import 'package:funny_loan/app/network/utils/crypto_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mine popup request uses personal center scene', () async {
    final apiService = _FakeApiService();
    final controller = MineController()..onNetworkReady(apiService);

    await controller.fetchPopup();

    expect(apiService.popupParams, <String, dynamic>{'interferons': 2});
  });

  test('mine popup request ignores concurrent refresh', () async {
    final apiService = _FakeApiService(delay: const Duration(milliseconds: 10));
    final controller = MineController()..onNetworkReady(apiService);

    unawaited(controller.fetchPopup());
    await controller.fetchPopup();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(apiService.popupRequestCount, 1);
  });
}

class _FakeApiService extends ApiService {
  _FakeApiService({this.delay = Duration.zero})
    : super(
        client: NetworkClient(
          dio: Dio(),
          config: _dummyConfig,
          state: MutableNetworkState(apiBaseUrl: '', webBaseUrl: ''),
          commonParamsProvider: CommonParamsProvider(_dummyConfig),
          responseParser: ResponseParser(
            config: _dummyConfig,
            authExpiryGuard: AuthExpiryGuard(_dummyConfig),
          ),
        ),
        cryptoUtil: const CryptoUtil(
          key: '1234567890abcdef',
          iv: 'abcdef1234567890',
        ),
      );

  static final NetworkConfig _dummyConfig = NetworkConfig.funnyLoanIos(
    defaultApiBaseUrl: '',
    defaultWebBaseUrl: '',
    remoteConfigUrl: '',
    signatureSecret: 'secret',
    cryptoKey: '1234567890abcdef',
    cryptoIv: 'abcdef1234567890',
  );

  final Duration delay;
  int popupRequestCount = 0;
  Map<String, dynamic>? popupParams;

  @override
  Future<NetworkResponse> fetchPopup(Map<String, dynamic> params) async {
    popupRequestCount += 1;
    popupParams = Map<String, dynamic>.from(params);
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return NetworkResponse(
      code: 0,
      message: 'success',
      data: Json(<String, dynamic>{'outcrop': 0}),
      raw: const <String, dynamic>{'outcrop': 0},
    );
  }
}
