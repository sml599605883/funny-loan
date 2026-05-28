typedef AsyncCommonParamsProvider = Future<Map<String, dynamic>> Function();
typedef SyncCommonParamsProvider = Map<String, dynamic> Function();
typedef AuthExpiredCallback = Future<void> Function();

class NetworkConfig {
  const NetworkConfig({
    required this.defaultApiBaseUrl,
    required this.defaultWebBaseUrl,
    required this.remoteConfigUrl,
    required this.successCodes,
    required this.authExpiredCode,
    required this.signatureSecret,
    required this.signatureFieldName,
    required this.signaturePathFieldName,
    required this.queryRandomFieldName,
    required this.businessRandomFieldName,
    required this.cryptoKey,
    required this.cryptoIv,
    this.codeKey = 'code',
    this.messageKey = 'msg',
    this.alternateMessageKey = 'message',
    this.dataKey = 'data',
    this.staticCommonParams = const {},
    this.asyncCommonParamsProvider,
    this.syncCommonParamsProvider,
    this.authExpiredCallback,
  });

  final String defaultApiBaseUrl;
  final String defaultWebBaseUrl;
  final String remoteConfigUrl;
  final Set<int> successCodes;
  final int authExpiredCode;
  final String signatureSecret;
  final String signatureFieldName;
  final String signaturePathFieldName;
  final String queryRandomFieldName;
  final String businessRandomFieldName;
  final String cryptoKey;
  final String cryptoIv;
  final String codeKey;
  final String messageKey;
  final String alternateMessageKey;
  final String dataKey;
  final Map<String, dynamic> staticCommonParams;
  final AsyncCommonParamsProvider? asyncCommonParamsProvider;
  final SyncCommonParamsProvider? syncCommonParamsProvider;
  final AuthExpiredCallback? authExpiredCallback;

  factory NetworkConfig.funnyLoanIos({
    required String defaultApiBaseUrl,
    required String defaultWebBaseUrl,
    required String remoteConfigUrl,
    required String signatureSecret,
    required String cryptoKey,
    required String cryptoIv,
    Map<String, dynamic> staticCommonParams = const {},
    AsyncCommonParamsProvider? asyncCommonParamsProvider,
    SyncCommonParamsProvider? syncCommonParamsProvider,
    AuthExpiredCallback? authExpiredCallback,
  }) {
    return NetworkConfig(
      defaultApiBaseUrl: defaultApiBaseUrl,
      defaultWebBaseUrl: defaultWebBaseUrl,
      remoteConfigUrl: remoteConfigUrl,
      successCodes: const {0},
      authExpiredCode: -2,
      signatureSecret: signatureSecret,
      signatureFieldName: 'slipcase',
      signaturePathFieldName: 'noris',
      queryRandomFieldName: 'cycloid',
      businessRandomFieldName: 'biz_nonce',
      cryptoKey: cryptoKey,
      cryptoIv: cryptoIv,
      staticCommonParams: <String, dynamic>{
        'rationalistic': 'appstore-ph-funny-loan-ios',
        ...staticCommonParams,
      },
      asyncCommonParamsProvider: asyncCommonParamsProvider,
      syncCommonParamsProvider: syncCommonParamsProvider,
      authExpiredCallback: authExpiredCallback,
    );
  }

  NetworkConfig copyWith({
    String? defaultApiBaseUrl,
    String? defaultWebBaseUrl,
    String? remoteConfigUrl,
    Set<int>? successCodes,
    int? authExpiredCode,
    Map<String, dynamic>? staticCommonParams,
    AsyncCommonParamsProvider? asyncCommonParamsProvider,
    SyncCommonParamsProvider? syncCommonParamsProvider,
    AuthExpiredCallback? authExpiredCallback,
  }) {
    return NetworkConfig(
      defaultApiBaseUrl: defaultApiBaseUrl ?? this.defaultApiBaseUrl,
      defaultWebBaseUrl: defaultWebBaseUrl ?? this.defaultWebBaseUrl,
      remoteConfigUrl: remoteConfigUrl ?? this.remoteConfigUrl,
      successCodes: successCodes ?? this.successCodes,
      authExpiredCode: authExpiredCode ?? this.authExpiredCode,
      signatureSecret: signatureSecret,
      signatureFieldName: signatureFieldName,
      signaturePathFieldName: signaturePathFieldName,
      queryRandomFieldName: queryRandomFieldName,
      businessRandomFieldName: businessRandomFieldName,
      cryptoKey: cryptoKey,
      cryptoIv: cryptoIv,
      codeKey: codeKey,
      messageKey: messageKey,
      alternateMessageKey: alternateMessageKey,
      dataKey: dataKey,
      staticCommonParams: staticCommonParams ?? this.staticCommonParams,
      asyncCommonParamsProvider:
          asyncCommonParamsProvider ?? this.asyncCommonParamsProvider,
      syncCommonParamsProvider:
          syncCommonParamsProvider ?? this.syncCommonParamsProvider,
      authExpiredCallback: authExpiredCallback ?? this.authExpiredCallback,
    );
  }
}

class MutableNetworkState {
  MutableNetworkState({
    required this.apiBaseUrl,
    required this.webBaseUrl,
  });

  String apiBaseUrl;
  String webBaseUrl;
}
