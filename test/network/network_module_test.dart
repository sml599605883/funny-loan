import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funny_loan/app/network/client/network_client.dart';
import 'package:funny_loan/app/network/config/network_bootstrapper.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/network/core/auth_expiry_guard.dart';
import 'package:funny_loan/app/network/core/common_params_provider.dart';
import 'package:funny_loan/app/network/core/response_parser.dart';
import 'package:funny_loan/app/network/errors/network_exception.dart';
import 'package:funny_loan/app/network/models/network_response.dart';
import 'package:funny_loan/app/network/utils/crypto_util.dart';
import 'package:funny_loan/app/network/utils/signature_util.dart';

void main() {
  group('NetworkClient', () {
    late _RecordingAdapter adapter;
    late NetworkClient client;

    setUp(() {
      adapter = _RecordingAdapter();
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      dio.httpClientAdapter = adapter;

      final config = _testConfig();
      client = NetworkClient(
        dio: dio,
        config: config,
        state: MutableNetworkState(
          apiBaseUrl: config.defaultApiBaseUrl,
          webBaseUrl: config.defaultWebBaseUrl,
        ),
        commonParamsProvider: CommonParamsProvider(config),
        responseParser: ResponseParser(
          config: config,
          authExpiryGuard: AuthExpiryGuard(config),
        ),
      );
    });

    test(
      'GET places common params, sign and business params in query',
      () async {
        await client.get('/loan/list', query: const {'page': 1, 'size': 20});

        final options = adapter.lastOptions!;
        expect(options.method, 'GET');
        expect(options.uri.path, '/loan/list');
        expect(options.uri.queryParameters['tonometry'], '1.0.0');
        expect(options.uri.queryParameters['lobate'], 'iPhone 15');
        expect(options.uri.queryParameters['clepes'], 'device-001');
        expect(
          options.uri.queryParameters['rationalistic'],
          'appstore-ph-funny-loan-ios',
        );
        expect(options.uri.queryParameters['page'], '1');
        expect(options.uri.queryParameters['size'], '20');
        expect(options.uri.queryParameters['slipcase'], isNotEmpty);
        expect(
          options.uri.queryParameters['cycloid'],
          matches(RegExp(r'^\d{6}$')),
        );
        expect(
          options.uri.queryParameters['expressionism'],
          matches(RegExp(r'^\d{13}$')),
        );
      },
    );

    test(
      'POST keeps business params in body and signable params in query',
      () async {
        await client.post(
          '/loan/apply',
          body: const {'amount': '120000', 'period': 12},
        );

        final options = adapter.lastOptions!;
        expect(options.method, 'POST');
        expect(options.uri.queryParameters['tonometry'], '1.0.0');
        expect(options.uri.queryParameters['amount'], isNull);
        expect(options.uri.queryParameters['period'], isNull);
        expect(options.data, isA<Map<String, dynamic>>());
        final body = options.data! as Map<String, dynamic>;
        expect(body['amount'], '120000');
        expect(body['period'], 12);
        expect(body['biz_nonce'], matches(RegExp(r'^\d{6}$')));
      },
    );

    test('upload keeps files and business params in multipart body', () async {
      final tempDir = await Directory.systemTemp.createTemp('funny_loan_test');
      final file = File('${tempDir.path}/sample.txt');
      await file.writeAsString('upload');

      try {
        await client.upload(
          '/loan/upload',
          body: const {'orderNo': 'A1001'},
          files: [
            UploadFilePart(
              fieldName: 'attachment',
              filePath: file.path,
              fileName: 'sample.txt',
            ),
          ],
        );

        final options = adapter.lastOptions!;
        expect(options.method, 'POST');
        expect(options.uri.queryParameters['tonometry'], '1.0.0');
        expect(options.data, isA<FormData>());
        final formData = options.data! as FormData;
        expect(
          formData.fields.any(
            (entry) => entry.key == 'orderNo' && entry.value == 'A1001',
          ),
          isTrue,
        );
        expect(
          formData.fields.any((entry) => entry.key == 'biz_nonce'),
          isTrue,
        );
        expect(formData.files.length, 1);
        expect(formData.files.first.key, 'attachment');
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('ResponseParser', () {
    test('missing response fields fall back to json default values', () {
      final response = NetworkResponse.fromDynamic('invalid');
      expect(response.code, 0);
      expect(response.message, '');
      expect(response.data?.isNull(), isTrue);
    });

    test('auth expiry handler is idempotent under concurrency', () async {
      var authExpiredCallCount = 0;
      final config = _testConfig(
        authExpiredCode: 401,
        authExpiredCallback: () async {
          authExpiredCallCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
      );
      final parser = ResponseParser(
        config: config,
        authExpiryGuard: AuthExpiryGuard(config),
      );

      Future<void> parseExpired() async {
        await expectLater(
          parser.parse(const {
            'unplait': 401,
            'gluteal': 'expired',
            'rekeys': null,
          }),
          throwsA(isA<AuthExpiredException>()),
        );
      }

      await Future.wait([parseExpired(), parseExpired(), parseExpired()]);
      expect(authExpiredCallCount, 1);
    });
  });

  group('Bootstrapper', () {
    test('keeps default base urls when default api is reachable', () async {
      final dio = Dio(BaseOptions(validateStatus: (_) => true));
      dio.httpClientAdapter = _QueueAdapter([
        _MockReply(statusCode: 200, data: const {'ok': true}),
      ]);

      final config = _testConfig(
        defaultApiBaseUrl: 'https://default.example.com',
        defaultWebBaseUrl: 'https://web.example.com',
        remoteConfigUrl: 'https://config.example.com',
      );
      final state = await NetworkBootstrapper(dio).bootstrap(config);

      expect(state.apiBaseUrl, 'https://default.example.com');
      expect(state.webBaseUrl, 'https://web.example.com');
    });

    test(
      'falls back to plain json remote config when default api is unavailable',
      () async {
        final dio = Dio(BaseOptions(validateStatus: (_) => true));
        dio.httpClientAdapter = _QueueAdapter([
          _MockReply(statusCode: 500, data: const {'error': true}),
          _MockReply(
            statusCode: 200,
            data: const {
              'apiBaseUrl': 'https://backup.example.com',
              'webBaseUrl': 'https://backup-web.example.com',
            },
          ),
        ]);

        final config = _testConfig(
          defaultApiBaseUrl: 'https://default.example.com',
          defaultWebBaseUrl: 'https://web.example.com',
          remoteConfigUrl: 'https://config.example.com',
        );
        final state = await NetworkBootstrapper(dio).bootstrap(config);

        expect(state.apiBaseUrl, 'https://backup.example.com');
        expect(state.webBaseUrl, 'https://backup-web.example.com');
      },
    );

    test('falls back to base64 encoded remote config when needed', () async {
      final dio = Dio(BaseOptions(validateStatus: (_) => true));
      dio.httpClientAdapter = _QueueAdapter([
        _MockReply(statusCode: 503, data: const {'error': true}),
        _MockReply(
          statusCode: 200,
          data: base64Encode(
            utf8.encode(
              jsonEncode(const {
                'apiBaseUrl': 'https://base64.example.com',
                'webBaseUrl': 'https://base64-web.example.com',
              }),
            ),
          ),
        ),
      ]);

      final config = _testConfig(
        defaultApiBaseUrl: 'https://default.example.com',
        defaultWebBaseUrl: 'https://web.example.com',
        remoteConfigUrl: 'https://config.example.com',
      );
      final state = await NetworkBootstrapper(dio).bootstrap(config);

      expect(state.apiBaseUrl, 'https://base64.example.com');
      expect(state.webBaseUrl, 'https://base64-web.example.com');
    });
  });

  group('Utilities', () {
    test('signature generation is deterministic', () {
      final signature = SignatureUtil.generate(
        mappedCommonParams: const {
          'clepes': 'device-001',
          'tonometry': '1.0.0',
        },
        pathFieldName: 'noris',
        path: '/loan/list',
        secret: '2ad42edd9ae3951b56b527ddc6b054d0',
      );

      expect(
        signature,
        '4667dcc2ab5d6e3ff22c49d9e8e88345c7d1b57d6ce2c2c61df4843fa2d3b817',
      );
    });

    test('crypto util can encrypt and decrypt plain text', () {
      const cryptoUtil = CryptoUtil(
        key: '1234567890abcdef',
        iv: 'abcdef1234567890',
      );

      final encrypted = cryptoUtil.encryptToBase64('hello loan');
      final decrypted = cryptoUtil.decryptFromBase64(encrypted);

      expect(encrypted, isNotEmpty);
      expect(decrypted, 'hello loan');
    });
  });
}

NetworkConfig _testConfig({
  String defaultApiBaseUrl = 'https://api.example.com',
  String defaultWebBaseUrl = 'https://h5.example.com',
  String remoteConfigUrl = '',
  int authExpiredCode = 401,
  Future<void> Function()? authExpiredCallback,
}) {
  return NetworkConfig.funnyLoanIos(
    defaultApiBaseUrl: defaultApiBaseUrl,
    defaultWebBaseUrl: defaultWebBaseUrl,
    remoteConfigUrl: remoteConfigUrl,
    signatureSecret: '2ad42edd9ae3951b56b527ddc6b054d0',
    cryptoKey: '1234567890abcdef',
    cryptoIv: 'abcdef1234567890',
    staticCommonParams: const {
      'tonometry': '1.0.0',
      'lobate': 'iPhone 15',
      'clepes': 'device-001',
      'sextet': '18.0',
      'manioc': 'session-001',
      'compliant': 'device-001',
    },
    authExpiredCallback: authExpiredCallback,
  ).copyWith(authExpiredCode: authExpiredCode);
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      jsonEncode(const {
        'unplait': 0,
        'gluteal': 'ok',
        'rekeys': {'success': true},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this._replies);

  final List<_MockReply> _replies;
  int _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final reply = _replies[_index++];
    final body = reply.data is String
        ? reply.data as String
        : jsonEncode(reply.data);
    return ResponseBody.fromString(
      body,
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockReply {
  const _MockReply({required this.statusCode, required this.data});

  final int statusCode;
  final Object data;
}
