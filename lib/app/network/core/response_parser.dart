import '../config/network_config.dart';
import '../errors/network_exception.dart';
import '../models/network_response.dart';
import 'auth_expiry_guard.dart';

class ResponseParser {
  ResponseParser({
    required NetworkConfig config,
    required AuthExpiryGuard authExpiryGuard,
  })  : _config = config,
        _authExpiryGuard = authExpiryGuard;

  final NetworkConfig _config;
  final AuthExpiryGuard _authExpiryGuard;

  Future<NetworkResponse<dynamic>> parse(dynamic raw) async {
    final response = NetworkResponse<dynamic>.fromDynamic(
      raw,
      codeKey: _config.codeKey,
      messageKey: _config.messageKey,
      alternateMessageKey: _config.alternateMessageKey,
      dataKey: _config.dataKey,
    );

    if (_config.authExpiredCode == response.code) {
      await _authExpiryGuard.handle();
      throw AuthExpiredException(response.message, code: response.code);
    }

    if (!_config.successCodes.contains(response.code)) {
      throw NetworkException(response.message, code: response.code);
    }

    return response;
  }
}
