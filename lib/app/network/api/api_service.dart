import '../client/network_client.dart';
import '../errors/network_exception.dart';
import '../models/network_response.dart';
import '../utils/crypto_util.dart';

class ApiService {
  ApiService({
    required NetworkClient client,
    required CryptoUtil cryptoUtil,
  })  : _client = client,
        _cryptoUtil = cryptoUtil;

  final NetworkClient _client;
  final CryptoUtil _cryptoUtil;

  Future<NetworkResponse<dynamic>> getExample(
    Map<String, dynamic> params,
  ) {
    return _client.get('/example/get', query: params);
  }

  Future<NetworkResponse<dynamic>> postExample(
    Map<String, dynamic> body,
  ) {
    return _client.post('/example/post', body: body);
  }

  Future<NetworkResponse<dynamic>> uploadExample({
    required Map<String, dynamic> body,
    String? filePath,
  }) {
    if (filePath == null || filePath.isEmpty) {
      return _client.post('/example/upload-fallback', body: body);
    }
    return _client.upload(
      '/example/upload',
      body: body,
      files: [
        UploadFilePart(
          fieldName: 'file',
          filePath: filePath,
        ),
      ],
    );
  }

  Future<NetworkResponse<dynamic>> encryptedReport({
    String? plainText,
    String? encryptedText,
  }) {
    final payload = encryptedText ??
        (plainText == null ? null : _cryptoUtil.encryptToBase64(plainText));
    if (payload == null || payload.isEmpty) {
      throw const NetworkException('Encrypted payload is empty');
    }
    return _client.post(
      '/example/report',
      body: <String, dynamic>{'payload': payload},
    );
  }
}
