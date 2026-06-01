import '../client/network_client.dart';
import '../errors/network_exception.dart';
import '../models/network_response.dart';
import '../utils/crypto_util.dart';
import '../utils/random_util.dart';

class ApiService {
  ApiService({required NetworkClient client, required CryptoUtil cryptoUtil})
    : _client = client,
      _cryptoUtil = cryptoUtil;

  final NetworkClient _client;
  final CryptoUtil _cryptoUtil;

  Map<String, dynamic> _withObfuscatedFields(
    Map<String, dynamic> source,
    List<String> obfuscatedFieldNames,
  ) {
    final payload = Map<String, dynamic>.from(source);
    for (final fieldName in obfuscatedFieldNames) {
      final value = payload[fieldName];
      if (value == null || (value is String && value.isEmpty)) {
        payload[fieldName] = RandomUtil.numeric(9);
      }
    }
    return payload;
  }

  /// 用户账号-获取登录/注册短信验证码 POST /consultancy/grieving
  Future<NetworkResponse> requestLoginSmsCode(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/grieving',
      body: _withObfuscatedFields(body, const ['proscenium']),
    );
  }

  /// 用户账号-验证码登录/注册 POST /consultancy/proscenium
  Future<NetworkResponse> loginOrRegisterWithCode(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/proscenium',
      body: _withObfuscatedFields(body, const ['elmiest', 'stowages']),
    );
  }

  /// 用户账号-退出登录 GET /consultancy/unplait
  Future<NetworkResponse> logout(Map<String, dynamic> params) {
    return _client.get(
      '/consultancy/unplait',
      query: _withObfuscatedFields(params, const ['plenist', 'miniaturized']),
    );
  }

  /// 用户账号-注销账号 GET /consultancy/gluteal
  Future<NetworkResponse> deleteAccount(Map<String, dynamic> params) {
    return _client.get(
      '/consultancy/gluteal',
      query: _withObfuscatedFields(params, const ['fattinesses']),
    );
  }

  /// App相关-APP首页 GET /consultancy/rekeys
  Future<NetworkResponse> fetchAppHome(Map<String, dynamic> params) {
    return _client.get(
      '/consultancy/rekeys',
      query: _withObfuscatedFields(params, const [
        'orismological',
        'antidiarrheal',
      ]),
    );
  }

  /// App相关-个人中心 GET /consultancy/puristic
  Future<NetworkResponse> fetchProfileCenter(
    Map<String, dynamic> params,
  ) {
    return _client.get(
      '/consultancy/puristic',
      query: _withObfuscatedFields(params, const ['outspend']),
    );
  }

  /// App相关-app上报 POST /consultancy/supermarket
  Future<NetworkResponse> reportAppEvent(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/supermarket',
      body: _withObfuscatedFields(body, const ['skullduggery', 'jest']),
    );
  }

  /// App相关-重新授信 GET /consultancy/elmiest
  Future<NetworkResponse> refreshCredit(Map<String, dynamic> params) {
    return _client.get(
      '/consultancy/elmiest',
      query: _withObfuscatedFields(params, const ['forevers']),
    );
  }

  /// App相关-弹窗 GET /consultancy/stowages
  Future<NetworkResponse> fetchPopup(Map<String, dynamic> params) {
    return _client.get('/consultancy/stowages', query: params);
  }

  /// App相关-上传banner点击记录 POST /consultancy/indigotin
  Future<NetworkResponse> uploadBannerClickRecord(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/indigotin',
      body: _withObfuscatedFields(body, const ['disdaining']),
    );
  }

  /// App相关-根据标识符查询IOS设备信息 POST /consultancy/blumed
  Future<NetworkResponse> queryIosDeviceInfo(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/blumed',
      body: _withObfuscatedFields(body, const ['disdaining']),
    );
  }

  /// 产品相关-点击申请 POST /consultancy/antigenicities
  Future<NetworkResponse> applyProduct(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/antigenicities',
      body: _withObfuscatedFields(body, const ['polemic', 'sociableness']),
    );
  }

  /// 产品相关-产品详情 POST /consultancy/sneesh
  Future<NetworkResponse> fetchProductDetail(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/sneesh',
      body: _withObfuscatedFields(body, const ['pyrene', 'etiology', 'lutes']),
    );
  }

  /// 认证项-获取用户身份信息 GET /consultancy/plenist
  Future<NetworkResponse> fetchIdentityInfo(
    Map<String, dynamic> params,
  ) {
    return _client.get(
      '/consultancy/plenist',
      query: _withObfuscatedFields(params, const ['certiorari']),
    );
  }

  /// 认证项-上传人脸或身份证正面 POST/UPLOAD /consultancy/miniaturized
  Future<NetworkResponse> uploadIdentityOrFace({
    required Map<String, dynamic> body,
    String? filePath,
  }) {
    if (filePath == null || filePath.isEmpty) {
      return _client.post('/consultancy/miniaturized', body: body);
    }
    return _client.upload(
      '/consultancy/miniaturized',
      body: body,
      files: [UploadFilePart(fieldName: 'attach', filePath: filePath)],
    );
  }

  /// 认证项-保存用户身份证信息 POST /consultancy/fattinesses
  Future<NetworkResponse> saveIdentityInfo(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/fattinesses',
      body: _withObfuscatedFields(body, const ['cycloid']),
    );
  }

  /// 认证项-获取face++ token POST /consultancy/antidiarrheal
  Future<NetworkResponse> fetchFaceToken(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/antidiarrheal',
      body: _withObfuscatedFields(body, const ['uncertified', 'cougher']),
    );
  }

  /// 认证项-获取用户信息（第二项） POST /consultancy/keelboat
  Future<NetworkResponse> fetchUserInfo(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/keelboat',
      body: _withObfuscatedFields(body, const ['thurible']),
    );
  }

  /// 认证项-保存用户信息（第二项） POST /consultancy/outcrop
  Future<NetworkResponse> saveUserInfo(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/outcrop',
      body: _withObfuscatedFields(body, const ['thanksgiving', 'snugged']),
    );
  }

  /// 认证项-获取工作信息（第三项） GET /consultancy/federalizes
  Future<NetworkResponse> fetchWorkInfo(Map<String, dynamic> params) {
    return _client.get(
      '/consultancy/federalizes',
      query: _withObfuscatedFields(params, const ['thurible']),
    );
  }

  /// 认证项-保存工作信息（第三项） POST /consultancy/isolines
  Future<NetworkResponse> saveWorkInfo(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/isolines',
      body: _withObfuscatedFields(body, const [
        'outsmelling',
        'banco',
        'kymographs',
      ]),
    );
  }

  /// 认证项-获取联系人信息（第四项） GET /consultancy/sidearms
  Future<NetworkResponse> fetchContactInfo(
    Map<String, dynamic> params,
  ) {
    return _client.get(
      '/consultancy/sidearms',
      query: _withObfuscatedFields(params, const ['fascias']),
    );
  }

  /// 认证项-保存联系人信息（第四项） POST /consultancy/lectin
  Future<NetworkResponse> saveContactInfo(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/lectin',
      body: _withObfuscatedFields(body, const ['empirically']),
    );
  }

  /// 认证项-获取绑卡信息（第五项） GET /consultancy/disprovable
  Future<NetworkResponse> fetchBindCardInfo(
    Map<String, dynamic> params,
  ) {
    return _client.get(
      '/consultancy/disprovable',
      query: _withObfuscatedFields(params, const ['zigzaggy', 'tocher']),
    );
  }

  /// 认证项-提交绑卡 POST/UPLOAD /consultancy/subsider
  Future<NetworkResponse> submitBindCard({
    required Map<String, dynamic> body,
    String? filePath,
  }) {
    if (filePath == null || filePath.isEmpty) {
      return _client.post(
        '/consultancy/subsider',
        body: _withObfuscatedFields(body, const ['ecotage']),
      );
    }
    final payload = _withObfuscatedFields(body, const ['ecotage']);
    return _client.upload(
      '/consultancy/subsider',
      body: payload,
      files: [UploadFilePart(fieldName: 'attach', filePath: filePath)],
    );
  }

  /// 认证项-地址初始化 GET /consultancy/overengineered
  Future<NetworkResponse> fetchAddressOptions() {
    return _client.get('/consultancy/overengineered');
  }

  /// 认证项-用户账户列表 POST /consultancy/decrial
  Future<NetworkResponse> fetchUserAccountList(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/decrial',
      body: _withObfuscatedFields(body, const ['rephotograph', 'preslaughter']),
    );
  }

  /// 认证项-更换银行卡 POST /consultancy/yesterday
  Future<NetworkResponse> changeBankCard(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/yesterday',
      body: _withObfuscatedFields(body, const ['hankered']),
    );
  }

  /// 认证项-获取挽留弹窗 POST /consultancy/cryptococci
  Future<NetworkResponse> fetchRetentionPopup(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/cryptococci',
      body: _withObfuscatedFields(body, const ['avidly']),
    );
  }

  /// 认证项-同盾report POST /consultancy/reifier
  Future<NetworkResponse> reportTongdun(Map<String, dynamic> body) {
    return _client.post('/consultancy/reifier', body: body);
  }

  /// 用户&订单相关-跟进订单号获取跳转地址 POST /consultancy/recitalists
  Future<NetworkResponse> fetchOrderRedirect(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/recitalists',
      body: _withObfuscatedFields(body, const [
        'deutoplasms',
        'tropologies',
        'rudderpost',
        'reconsiders',
      ]),
    );
  }

  /// 用户&订单相关-订单列表 POST /consultancy/scumbag
  Future<NetworkResponse> fetchOrderList(Map<String, dynamic> body) {
    return _client.post('/consultancy/scumbag', body: body);
  }

  /// 数据上报-上报位置信息 POST /consultancy/inflective
  Future<NetworkResponse> reportLocation(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/inflective',
      body: _withObfuscatedFields(body, const ['epileptogenic', 'preplaces']),
    );
  }

  /// 数据上报-google_market上报 POST /consultancy/landforms
  Future<NetworkResponse> reportGoogleMarket(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/landforms',
      body: _withObfuscatedFields(body, const ['unroasted']),
    );
  }

  /// 数据上报-上报风控埋点 POST /consultancy/surly
  Future<NetworkResponse> reportRiskEvent(Map<String, dynamic> body) {
    return _client.post(
      '/consultancy/surly',
      body: _withObfuscatedFields(body, const ['zigzaggy']),
    );
  }

  /// 数据上报-设备信息加密上报 POST /consultancy/carbonylations
  Future<NetworkResponse> reportEncryptedDeviceInfo({
    String? plainText,
    String? encryptedText,
  }) {
    final payload =
        encryptedText ??
        (plainText == null ? null : _cryptoUtil.encryptToBase64(plainText));
    if (payload == null || payload.isEmpty) {
      throw const NetworkException('Encrypted payload is empty');
    }
    return _client.post(
      '/consultancy/carbonylations',
      body: <String, dynamic>{'rekeys': payload},
    );
  }

  /// 数据上报-通讯录加密上报 POST /consultancy/topworks
  Future<NetworkResponse> reportEncryptedContacts(
    Map<String, dynamic> body,
  ) {
    return _client.post(
      '/consultancy/topworks',
      body: _withObfuscatedFields(body, const ['sanger', 'parqueting']),
    );
  }

  /// 数据上报-上报Apple推送token POST /consultancy/hazinesses
  Future<NetworkResponse> reportApplePushToken(
    Map<String, dynamic> body,
  ) {
    return _client.post('/consultancy/hazinesses', body: body);
  }
}
