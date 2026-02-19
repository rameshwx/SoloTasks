import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api/api_client.dart';

const _defaultApiBaseUrl = String.fromEnvironment(
  'SOLOTASKS_API_BASE_URL',
  defaultValue: 'http://51.255.201.31:18000',
);

final apiClientProvider = Provider<ApiClient>((_) {
  return ApiClient(baseUrl: _defaultApiBaseUrl);
});
