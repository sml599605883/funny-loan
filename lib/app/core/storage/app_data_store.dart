import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppDataStore {
  AppDataStore._();

  static const persistedPhoneKey = 'login_phone';
  static const persistedTokenKey = 'user_token';
  static const productDetailScabiosaCacheKey = 'product_detail_scabiosa';

  static final Map<String, Object?> _memoryCache = <String, Object?>{};
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefs {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('AppDataStore.init() must be called before use.');
    }
    return preferences;
  }

  static void setCache(String key, Object? value) {
    _memoryCache[key] = value;
  }

  static T? getCache<T>(String key) {
    final value = _memoryCache[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  static bool hasCache(String key) {
    return _memoryCache.containsKey(key);
  }

  static void removeCache(String key) {
    _memoryCache.remove(key);
  }

  static void clearCache() {
    _memoryCache.clear();
  }

  static Future<bool> setPersistentString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static String? getPersistentString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setPersistentBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static bool? getPersistentBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> setPersistentInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static int? getPersistentInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<bool> setPersistentDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  static double? getPersistentDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<bool> setPersistentStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  static List<String>? getPersistentStringList(String key) {
    return _prefs.getStringList(key);
  }

  static Future<bool> setPersistentJson(
    String key,
    Map<String, dynamic> value,
  ) {
    return _prefs.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getPersistentJson(String key) {
    final value = _prefs.getString(key);
    if (value == null || value.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return null;
  }

  static bool hasPersistent(String key) {
    return _prefs.containsKey(key);
  }

  static Future<bool> removePersistent(String key) {
    return _prefs.remove(key);
  }

  static Future<bool> clearPersistent() {
    return _prefs.clear();
  }
}
