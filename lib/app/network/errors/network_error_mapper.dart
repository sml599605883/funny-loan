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
        return 'Connection timeout. Please retry.';
      }
      if (error.type == DioExceptionType.sendTimeout) {
        return 'Connection timeout. Please retry.';
      }
      if (error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please retry.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Network error. Please try again.';
      }
      if (error.type == DioExceptionType.badCertificate) {
        return 'Network error. Please try again.';
      }
      if (error.type == DioExceptionType.badResponse) {
        return 'Network error. Please try again.';
      }
      return error.message ?? 'Network error. Please try again.';
    }
    return error.toString();
  }
}
