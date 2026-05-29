import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract class SignatureUtil {
  static String generate({
    required Map<String, dynamic> mappedCommonParams,
    required String pathFieldName,
    required String path,
    required String secret,
  }) {
    final Map<String, dynamic> payload = <String, dynamic>{
      ...mappedCommonParams,
      pathFieldName: path,
    };
    final keys = payload.keys.toList()..sort();
    final source = keys.map((key) => '$key${payload[key] ?? ''}').join();
    final digest = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(source));
    return digest.toString();
  }
}
