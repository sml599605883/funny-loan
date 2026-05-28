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
  })  : _dio = dio,
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

  Future<void> configureProxy({
    required String host,
    required int port,
    bool badCertificateAllowed = false,
  }) async {
    final adapter = _dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      throw StateError('Proxy configuration is only supported on IO platforms.');
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

  Future<NetworkResponse<dynamic>> get(
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

  Future<NetworkResponse<dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> businessRandomFields = const {},
  }) async {
    final request = await _buildRequestPayload(
      path: path,
      method: RequestMethod.post,
      businessParams: body,
      businessRandomFields: businessRandomFields,
    );
    final response = await _dio.postUri(
      _buildUri(path, request.queryParameters),
      data: request.body,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return _responseParser.parse(response.data);
  }

  Future<NetworkResponse<dynamic>> upload(
    String path, {
    Map<String, dynamic> body = const {},
    List<UploadFilePart> files = const [],
    Map<String, dynamic> businessRandomFields = const {},
  }) async {
    final request = await _buildRequestPayload(
      path: path,
      method: RequestMethod.upload,
      businessParams: body,
      businessRandomFields: businessRandomFields,
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
    Map<String, dynamic> businessRandomFields = const {},
  }) async {
    final commonParams = await _commonParamsProvider.getCommonParams();
    final queryParams = <String, dynamic>{
      ...commonParams,
      _config.queryRandomFieldName: RandomUtil.numeric(6),
    };
    final signature = SignatureUtil.generate(
      mappedCommonParams: commonParams,
      pathFieldName: _config.signaturePathFieldName,
      path: path,
      secret: _config.signatureSecret,
    );
    queryParams[_config.signatureFieldName] = signature;

    if (method == RequestMethod.get) {
      queryParams.addAll(businessParams);
      return _BuiltRequest(queryParameters: queryParams, body: const {});
    }

    final body = <String, dynamic>{
      ...businessParams,
      ...businessRandomFields,
    };
    if (businessRandomFields.isEmpty) {
      body[_config.businessRandomFieldName] = RandomUtil.numeric(6);
    }
    return _BuiltRequest(queryParameters: queryParams, body: body);
  }
}

class _BuiltRequest {
  const _BuiltRequest({
    required this.queryParameters,
    required this.body,
  });

  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> body;
}
