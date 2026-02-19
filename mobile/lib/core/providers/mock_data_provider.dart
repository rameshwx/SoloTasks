import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/drift/app_database.dart';
import '../logic/task_rules.dart';
import '../models/app_models.dart';
import 'api_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'sync_engine_provider.dart';

final taskListProvider =
    StateNotifierProvider<TaskListController, List<TaskViewModel>>((ref) {
  return TaskListController(ref);
});

class TaskListController extends StateNotifier<List<TaskViewModel>> {
  TaskListController(this._ref) : super(const <TaskViewModel>[]) {
    unawaited(_bootstrapFromLocalDb());
  }

  final Ref _ref;
  final Uuid _uuid = const Uuid();

  Future<void> bootstrap() => _bootstrapFromLocalDb();

  Future<void> _bootstrapFromLocalDb() async {
    final db = _ref.read(appDatabaseProvider);
    final rows = await (db.select(db.tasks)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    final loaded = rows.map(_taskFromRow).toList();
    _sortTasks(loaded);
    state = loaded;
    await _attemptSync();
  }

  Future<void> addQuickTask({
    required String title,
    required DateTime dateLocal,
    required int startMin,
    required int endMin,
    String? description,
    List<String> tags = const [],
  }) async {
    validateTaskWindow(startMin: startMin, endMin: endMin);

    final task = TaskViewModel(
      id: _uuid.v4(),
      title: title,
      status: TaskStatus.todo,
      dateLocal: DateTime(dateLocal.year, dateLocal.month, dateLocal.day),
      startMin: startMin,
      endMin: endMin,
      tags: tags,
      totalSubtasks: 0,
      doneSubtasks: 0,
      hasAttachment: false,
    );

    final now = DateTime.now().toUtc();
    final next = [...state, task];
    _sortTasks(next);
    state = next;

    await _upsertTaskLocally(
      task: task,
      now: now,
      enqueueOutbox: true,
      description: description,
    );
    await _attemptSync();
  }

  Future<void> rescheduleTask({
    required String taskId,
    required DateTime dateLocal,
    required int startMin,
    required int endMin,
  }) async {
    validateTaskWindow(startMin: startMin, endMin: endMin);

    TaskViewModel? updated;
    final now = DateTime.now().toUtc();
    final next = state.map((task) {
      if (task.id != taskId) return task;
      updated = TaskViewModel(
        id: task.id,
        title: task.title,
        status: task.status,
        dateLocal: DateTime(dateLocal.year, dateLocal.month, dateLocal.day),
        startMin: startMin,
        endMin: endMin,
        tags: task.tags,
        totalSubtasks: task.totalSubtasks,
        doneSubtasks: task.doneSubtasks,
        hasAttachment: task.hasAttachment,
      );
      return updated!;
    }).toList();

    if (updated == null) return;

    _sortTasks(next);
    state = next;

    await _upsertTaskLocally(task: updated!, now: now, enqueueOutbox: true);
    await _attemptSync();
  }

  Future<void> _upsertTaskLocally({
    required TaskViewModel task,
    required DateTime now,
    required bool enqueueOutbox,
    String? description,
  }) async {
    final db = _ref.read(appDatabaseProvider);

    await db.into(db.tasks).insertOnConflictUpdate(
          TasksCompanion(
            id: Value(task.id),
            userId: const Value('self'),
            title: Value(task.title),
            description: Value(description),
            status: Value(_statusToApi(task.status)),
            dateLocal: Value(_dateString(task.dateLocal)),
            startMin: Value(task.startMin),
            endMin: Value(task.endMin),
            durationMin: Value(task.endMin - task.startMin),
            createdAt: Value(now),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ),
        );

    if (!enqueueOutbox) return;

    final payload = {
      'title': task.title,
      'description': description,
      'status': _statusToApi(task.status),
      'dateLocal': _dateString(task.dateLocal),
      'startMin': task.startMin,
      'endMin': task.endMin,
      'durationMin': task.endMin - task.startMin,
      'seriesId': null,
      'seriesIndex': null,
      'seriesTotal': null,
    };

    await db.into(db.outboxOps).insert(
          OutboxOpsCompanion.insert(
            id: _uuid.v4(),
            opId: _uuid.v4(),
            entity: 'task',
            action: 'upsert',
            entityId: task.id,
            payloadJson: jsonEncode(payload),
            clientTs: now,
            retryCount: const Value(0),
          ),
        );
  }

  Future<void> _attemptSync() async {
    final session = _ref.read(sessionServiceProvider);
    final syncEngine = _ref.read(syncEngineProvider);
    final api = _ref.read(apiClientProvider);

    final deviceId = await session.getOrCreateDeviceId();
    var accessToken = await session.getAccessToken();
    final refreshToken = await session.getRefreshToken();

    if (accessToken == null || accessToken.isEmpty) return;

    try {
      final changes = await syncEngine.sync(
        accessToken: accessToken,
        deviceId: deviceId,
      );
      await _applyRemoteChanges(changes);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        final refreshed = await api.refresh(refreshToken: refreshToken);
        final body = refreshed.data as Map<String, dynamic>;
        final nextAccess = body['accessToken'] as String?;
        if (nextAccess == null || nextAccess.isEmpty) return;

        await session.updateAccessToken(nextAccess);
        accessToken = nextAccess;

        final changes = await syncEngine.sync(
          accessToken: accessToken,
          deviceId: deviceId,
        );
        await _applyRemoteChanges(changes);
      }
    }
  }

  Future<void> _applyRemoteChanges(List<Map<String, dynamic>> changes) async {
    if (changes.isEmpty) return;

    var next = [...state];
    final db = _ref.read(appDatabaseProvider);
    final now = DateTime.now().toUtc();

    for (final change in changes) {
      if ((change['entity'] as String?)?.toLowerCase() != 'task') continue;

      final action = (change['action'] as String?)?.toLowerCase() ?? '';
      final entityId =
          (change['entityId'] as String?) ?? (change['entity_id'] as String?);
      if (entityId == null || entityId.isEmpty) continue;

      if (action == 'delete') {
        next.removeWhere((task) => task.id == entityId);
        await (db.update(db.tasks)..where((tbl) => tbl.id.equals(entityId)))
            .write(
          TasksCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        continue;
      }

      final record = change['record'];
      if (record is! Map) continue;
      final data = record.cast<String, dynamic>();

      final dateValue =
          (data['date_local'] as String?) ?? (data['dateLocal'] as String?);
      final startValue =
          (data['start_min'] as num?) ?? (data['startMin'] as num?);
      final endValue = (data['end_min'] as num?) ?? (data['endMin'] as num?);
      final titleValue = data['title'] as String?;
      final statusValue = (data['status'] as String?) ?? 'todo';

      if (dateValue == null ||
          startValue == null ||
          endValue == null ||
          titleValue == null) {
        continue;
      }

      final task = TaskViewModel(
        id: entityId,
        title: titleValue,
        status: _statusFromApi(statusValue),
        dateLocal: _parseDate(dateValue),
        startMin: startValue.toInt(),
        endMin: endValue.toInt(),
        tags: const [],
        totalSubtasks: 0,
        doneSubtasks: 0,
        hasAttachment: false,
      );

      next = [
        for (final existing in next)
          if (existing.id == entityId) task else existing,
      ];
      if (!next.any((item) => item.id == entityId)) {
        next.add(task);
      }

      await _upsertTaskLocally(task: task, now: now, enqueueOutbox: false);
    }

    _sortTasks(next);
    state = next;
  }

  TaskViewModel _taskFromRow(Task row) {
    return TaskViewModel(
      id: row.id,
      title: row.title,
      status: _statusFromApi(row.status),
      dateLocal: _parseDate(row.dateLocal),
      startMin: row.startMin,
      endMin: row.endMin ?? (row.startMin + (row.durationMin ?? 60)),
      tags: const [],
      totalSubtasks: 0,
      doneSubtasks: 0,
      hasAttachment: false,
    );
  }

  String _dateString(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String _statusToApi(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => 'todo',
      TaskStatus.inProgress => 'in_progress',
      TaskStatus.blocked => 'blocked',
      TaskStatus.done => 'done',
    };
  }

  TaskStatus _statusFromApi(String value) {
    return switch (value) {
      'in_progress' => TaskStatus.inProgress,
      'blocked' => TaskStatus.blocked,
      'done' => TaskStatus.done,
      _ => TaskStatus.todo,
    };
  }

  void _sortTasks(List<TaskViewModel> tasks) {
    tasks.sort(
      (a, b) {
        final byDay = a.dateLocal.compareTo(b.dateLocal);
        if (byDay != 0) return byDay;
        return a.startMin.compareTo(b.startMin);
      },
    );
  }
}

final holidayDatesProvider = StateNotifierProvider<HolidayDatesController,
    Map<DateTime, List<HolidayType>>>((ref) {
  return HolidayDatesController(ref);
});

class HolidayDatesController
    extends StateNotifier<Map<DateTime, List<HolidayType>>> {
  HolidayDatesController(this._ref)
      : super(const <DateTime, List<HolidayType>>{}) {
    unawaited(_bootstrap());
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    final db = _ref.read(appDatabaseProvider);
    final rows = await (db.select(db.holidays)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    final mapped = <DateTime, List<HolidayType>>{};
    for (final row in rows) {
      final type = _parseType(row.type);
      if (type == null) continue;
      final day = _parseDate(row.dateLocal);
      mapped.putIfAbsent(day, () => <HolidayType>[]).add(type);
    }
    state = mapped;
  }

  void replaceAll(Map<DateTime, List<HolidayType>> next) {
    state = {
      for (final entry in next.entries) entry.key: [...entry.value],
    };
  }

  HolidayType? _parseType(String value) {
    return switch (value) {
      'bank' => HolidayType.bank,
      'public' => HolidayType.public,
      'mercantile' => HolidayType.mercantile,
      _ => null,
    };
  }

  DateTime _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
