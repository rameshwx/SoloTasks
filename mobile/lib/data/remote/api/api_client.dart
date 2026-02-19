import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  Future<Response<dynamic>> requestOtp(String email) {
    return _dio.post('/v1/auth/request-otp', data: {'email': email});
  }

  Future<Response<dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String deviceId,
    required String deviceName,
  }) {
    return _dio.post(
      '/v1/auth/verify-otp',
      data: {
        'email': email,
        'otp': otp,
        'deviceId': deviceId,
        'deviceName': deviceName,
      },
    );
  }

  Future<Response<dynamic>> syncPush({
    required String accessToken,
    required String deviceId,
    required List<Map<String, dynamic>> ops,
  }) {
    return _dio.post(
      '/v1/sync/push',
      data: {'deviceId': deviceId, 'ops': ops},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Response<dynamic>> syncPull({
    required String accessToken,
    required String deviceId,
    required int cursor,
  }) {
    return _dio.get(
      '/v1/sync/pull',
      queryParameters: {'deviceId': deviceId, 'cursor': cursor, 'limit': 500},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }
}
