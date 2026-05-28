import 'dart:developer';

import '../config/network_config.dart';

class AuthExpiryGuard {
  AuthExpiryGuard(this._config);

  final NetworkConfig _config;
  Future<void>? _processing;

  Future<void> handle() {
    return _processing ??= _execute().whenComplete(() {
      _processing = null;
    });
  }

  Future<void> _execute() async {
    log('Auth expired, clearing login state and redirecting.');
    await _config.authExpiredCallback?.call();
  }
}
