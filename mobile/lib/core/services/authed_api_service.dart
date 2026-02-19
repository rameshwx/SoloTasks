import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_provider.dart';
import '../providers/auth_provider.dart';

final authedApiServiceProvider = Provider<AuthedApiService>((ref) {
  return AuthedApiService(ref);
});

class AuthedApiService {
  AuthedApiService(this._ref);

  final Ref _ref;

  Future<T> run<T>(Future<T> Function(String accessToken) request) async {
    final session = _ref.read(sessionServiceProvider);
    final api = _ref.read(apiClientProvider);

    var accessToken = await session.getAccessToken();
    final refreshToken = await session.getRefreshToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Not authenticated');
    }

    try {
      return await request(accessToken);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        rethrow;
      }

      final refreshed = await api.refresh(refreshToken: refreshToken);
      final body = _asMap(refreshed.data);
      final nextAccess = body['accessToken']?.toString();
      if (nextAccess == null || nextAccess.isEmpty) {
        rethrow;
      }

      await session.updateAccessToken(nextAccess);
      accessToken = nextAccess;
      return request(accessToken);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return const <String, dynamic>{};
  }
}
