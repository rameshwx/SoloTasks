import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_engine.dart';
import 'api_provider.dart';
import 'database_provider.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
    ref: ref,
  );
});
