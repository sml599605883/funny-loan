import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/network_config.dart';
import '../core/common_params_provider.dart';
import '../core/response_parser.dart';
import '../models/network_response.dart';
import '../utils/random_util.dart';
import '../utils/signature_util.dart';

enum RequestMethod { get, post, upload }

class UploadFilePart {
  const UploadFilePart({
    required this.fieldName,
    required this.filePath,
    this.fileName,
  });

  final String fieldName;
  final String filePath;
  final String? fileName;
}

class NetworkClient {
  NetworkClient({
    required Dio dio,
    required NetworkConfig config,
    required MutableNetworkState state,
    required CommonParamsProvider commonParamsProvider,
    required ResponseParser responseParser,
  }) : _dio = dio,
       _config = config,
       _state = state,
       _commonParamsProvider = commonParamsProvider,
       _responseParser = responseParser;

  final Dio _dio;
  final NetworkConfig _config;
  final MutableNetworkState _state;
  final CommonParamsProvider _commonParamsProvider;
  final ResponseParser _responseParser;

  Dio get rawDio => _dio;

  void enableDebugCapture({
    String? proxyHost,
    int? proxyPort,
    bool badCertificateAllowed = true,
  }) {
    final adapter = _dio.httpClientAdapter;
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
      if (badCertificateAllowed) {
        client.badCertificateCallback = (_, _, _) => true;
      }
      return client;
    };
  }

  Future<void> configureProxy({
    required String host,
    required int port,
    bool badCertificateAllowed = false,
  }) async {
    final adapter = _dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      throw StateError(
        'Proxy configuration is only supported on IO platforms.',
      );
    }

    adapter.createHttpClient = () {
      final client = HttpClient();
      client.findProxy = (_) => 'PROXY $host:$port';
      if (badCertificateAllowed) {
        client.badCertificateCallback = (_, _, _) => true;
      }
      return client;
    };
  }

  Future<NetworkResponse> get(
    String path, {
    Map<String, dynamic> query = const {},
  }) async {
    final request = await _buildRequestPayload(
      path: path,
      method: RequestMethod.get,
      businessParams: query,
    );
    final response = await _dio.getUri(
      _buildUri(path, request.queryParameters),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return _responseParser.parse(response.data);
  }

  Future<NetworkResponse> post(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    final request = await _buildRequestPayload(
      path: path,
      method: RequestMethod.post,
      businessParams: body,
    );
    final response = await _dio.postUri(
      _buildUri(path, request.queryParameters),
      data: request.body,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return _responseParser.parse(response.data);
  }

  Future<NetworkResponse> upload(
    String path, {
    Map<String, dynamic> body = const {},
    List<UploadFilePart> files = const [],
  }) async {
    final request = await _buildRequestPayload(
      path: path,
      method: RequestMethod.upload,
      businessParams: body,
    );

    final formData = FormData.fromMap(<String, dynamic>{...request.body});
    for (final filePart in files) {
      formData.files.add(
        MapEntry(
          filePart.fieldName,
          await MultipartFile.fromFile(
            filePart.filePath,
            filename: filePart.fileName,
          ),
        ),
      );
    }

    final response = await _dio.postUri(
      _buildUri(path, request.queryParameters),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _responseParser.parse(response.data);
  }

  Future<Map<String, dynamic>> buildQueryParameters(
    String path, {
    Map<String, dynamic> businessParams = const {},
    RequestMethod method = RequestMethod.get,
  }) async {
    final request = await _buildRequestPayload(
      path: path,
      method: method,
      businessParams: businessParams,
    );
    return request.queryParameters;
  }

  Uri _buildUri(String path, Map<String, dynamic> queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${_state.apiBaseUrl}$normalizedPath').replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<_BuiltRequest> _buildRequestPayload({
    required String path,
    required RequestMethod method,
    required Map<String, dynamic> businessParams,
  }) async {
    final commonParams = await _commonParamsProvider.getCommonParams();
    final queryParams = <String, dynamic>{...commonParams};
    final signature = SignatureUtil.generate(
      mappedCommonParams: commonParams,
      pathFieldName: _config.signaturePathFieldName,
      path: path,
      secret: _config.signatureSecret,
    );
    queryParams[_config.signatureFieldName] = signature;
    queryParams[_config.queryRandomFieldName] = RandomUtil.numeric(6);

    if (method == RequestMethod.get) {
      queryParams.addAll(businessParams);
      return _BuiltRequest(queryParameters: queryParams, body: const {});
    }

    return _BuiltRequest(queryParameters: queryParams, body: businessParams);
  }
}

class _BuiltRequest {
  const _BuiltRequest({required this.queryParameters, required this.body});

  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> body;
}
