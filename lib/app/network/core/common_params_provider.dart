import '../config/network_config.dart';

class CommonParamsProvider {
  const CommonParamsProvider(this._config);

  final NetworkConfig _config;

  Future<Map<String, dynamic>> getCommonParams() async {
    if (_config.asyncCommonParamsProvider != null) {
      return _withTimestamp(await _config.asyncCommonParamsProvider!.call());
    }
    if (_config.syncCommonParamsProvider != null) {
      return _withTimestamp(_config.syncCommonParamsProvider!.call());
    }
    return _withTimestamp(_config.staticCommonParams);
  }

  Map<String, dynamic> _withTimestamp(Map<String, dynamic> params) {
    return <String, dynamic>{
      ...params,
      'expressionism': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}
