import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sync_provider.dart';
import '../local/drift/app_database.dart';
import '../remote/api/api_client.dart';

class SyncEngine {
  SyncEngine({
    required this.database,
    required this.apiClient,
    required this.ref,
  });

  final AppDatabase database;
  final ApiClient apiClient;
  final Ref ref;

  Future<List<Map<String, dynamic>>> sync({
    required String accessToken,
    required String deviceId,
  }) async {
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    try {
      final queued = await database.select(database.outboxOps).get();
      final ops = queued
          .map(
            (op) => {
              'opId': op.opId,
              'entity': op.entity,
              'action': op.action,
              'entityId': op.entityId,
              'payload': jsonDecode(op.payloadJson) as Map<String, dynamic>,
              'clientTs': op.clientTs.toUtc().toIso8601String(),
            },
          )
          .toList();

      if (ops.isNotEmpty) {
        await apiClient.syncPush(
          accessToken: accessToken,
          deviceId: deviceId,
          ops: ops,
        );
        await database.delete(database.outboxOps).go();
      }

      final syncStateRow = await database.select(database.syncState).getSingleOrNull();
      final cursor = syncStateRow?.cursor ?? 0;

      final pull = await apiClient.syncPull(
        accessToken: accessToken,
        deviceId: deviceId,
        cursor: cursor,
      );

      final body = pull.data as Map<String, dynamic>;
      final nextCursor = (body['cursor'] as num?)?.toInt() ?? cursor;
      final rawChanges = body['changes'];
      final changes = (rawChanges is List)
          ? rawChanges.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList()
          : <Map<String, dynamic>>[];

      await database.into(database.syncState).insertOnConflictUpdate(
            SyncStateCompanion(
              id: const Value('primary'),
              cursor: Value(nextCursor),
              lastSyncAt: Value(DateTime.now().toUtc()),
            ),
          );

      ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;
      return changes;
    } catch (_) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      rethrow;
    }
  }
}
