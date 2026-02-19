import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  final Dio _dio;
  String get baseUrl => _dio.options.baseUrl;

  Options _authOptions(String accessToken, {String? method}) {
    return Options(
      method: method,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

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

  Future<Response<dynamic>> refresh({required String refreshToken}) {
    return _dio.post('/v1/auth/refresh', data: {'refreshToken': refreshToken});
  }

  Future<Response<dynamic>> listTags({required String accessToken}) {
    return _dio.get('/v1/tags', options: _authOptions(accessToken));
  }

  Future<Response<dynamic>> createTag({
    required String accessToken,
    required String name,
    String? color,
  }) {
    return _dio.post(
      '/v1/tags',
      data: {
        'name': name,
        if (color != null && color.isNotEmpty) 'color': color,
      },
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> updateTag({
    required String accessToken,
    required String tagId,
    String? name,
    String? color,
  }) {
    return _dio.put(
      '/v1/tags/$tagId',
      data: {
        if (name != null) 'name': name,
        if (color != null) 'color': color,
      },
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> deleteTag({
    required String accessToken,
    required String tagId,
  }) {
    return _dio.delete(
      '/v1/tags/$tagId',
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> listTaskTags({
    required String accessToken,
    required String taskId,
  }) {
    return _dio.get(
      '/v1/tasks/$taskId/tags',
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> replaceTaskTags({
    required String accessToken,
    required String taskId,
    required List<String> tagIds,
  }) {
    return _dio.put(
      '/v1/tasks/$taskId/tags',
      data: {'tagIds': tagIds},
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> listReminders({required String accessToken}) {
    return _dio.get('/v1/reminders', options: _authOptions(accessToken));
  }

  Future<Response<dynamic>> createReminder({
    required String accessToken,
    required String targetType,
    required String targetId,
    DateTime? triggerAtUtc,
    int? offsetMinFromTaskStart,
  }) {
    return _dio.post(
      '/v1/reminders',
      data: {
        'targetType': targetType,
        'targetId': targetId,
        if (triggerAtUtc != null)
          'triggerAtUtc': triggerAtUtc.toUtc().toIso8601String(),
        if (offsetMinFromTaskStart != null)
          'offsetMinFromTaskStart': offsetMinFromTaskStart,
      },
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> updateReminder({
    required String accessToken,
    required String reminderId,
    DateTime? triggerAtUtc,
    int? offsetMinFromTaskStart,
  }) {
    return _dio.put(
      '/v1/reminders/$reminderId',
      data: {
        if (triggerAtUtc != null)
          'triggerAtUtc': triggerAtUtc.toUtc().toIso8601String(),
        if (offsetMinFromTaskStart != null)
          'offsetMinFromTaskStart': offsetMinFromTaskStart,
      },
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> deleteReminder({
    required String accessToken,
    required String reminderId,
  }) {
    return _dio.delete(
      '/v1/reminders/$reminderId',
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> listTaskAttachments({
    required String accessToken,
    required String taskId,
  }) {
    return _dio.get(
      '/v1/tasks/$taskId/attachments',
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> uploadInit({
    required String accessToken,
    required String taskId,
    required String fileName,
    required String mimeType,
    required int size,
  }) {
    return _dio.post(
      '/v1/attachments/upload-init',
      data: {
        'taskId': taskId,
        'fileName': fileName,
        'mimeType': mimeType,
        'size': size,
      },
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> uploadAttachmentBytes({
    required String accessToken,
    required String uploadUrl,
    required String method,
    required Map<String, String> headers,
    required List<int> bytes,
  }) {
    final isAbsolute =
        uploadUrl.startsWith('http://') || uploadUrl.startsWith('https://');
    final allHeaders = <String, String>{...headers};
    if (!isAbsolute) {
      allHeaders['Authorization'] = 'Bearer $accessToken';
    }

    final options = Options(method: method, headers: allHeaders);
    if (isAbsolute) {
      return _dio.requestUri<dynamic>(
        Uri.parse(uploadUrl),
        data: bytes,
        options: options,
      );
    }
    return _dio.request<dynamic>(
      uploadUrl,
      data: bytes,
      options: options,
    );
  }

  Future<Response<dynamic>> deleteAttachment({
    required String accessToken,
    required String attachmentId,
  }) {
    return _dio.delete(
      '/v1/attachments/$attachmentId',
      options: _authOptions(accessToken),
    );
  }

  String attachmentDownloadUrl(String attachmentId) {
    return '$baseUrl/v1/attachments/$attachmentId/download';
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
