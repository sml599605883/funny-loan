import 'package:dio/dio.dart';

import 'network_exception.dart';

abstract class NetworkErrorMapper {
  static String map(Object? error) {
    if (error == null) {
      return 'Unknown error';
    }
    if (error is NetworkException) {
      return error.message;
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.cancel) {
        return 'Request cancelled';
      }
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout';
      }
      if (error.type == DioExceptionType.sendTimeout) {
        return 'Request timeout';
      }
      if (error.type == DioExceptionType.receiveTimeout) {
        return 'Response timeout';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Network connection failed';
      }
      if (error.type == DioExceptionType.badCertificate) {
        return 'Certificate validation failed';
      }
      if (error.type == DioExceptionType.badResponse) {
        return 'Server response error';
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }
}
