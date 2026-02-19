import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/drift/app_database.dart';
import '../logic/task_rules.dart';
import '../models/app_models.dart';
import '../models/remote_models.dart';
import '../services/authed_api_service.dart';
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

  Future<TaskViewModel> addQuickTask({
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
    return task;
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

  Future<void> setTaskStatus({
    required String taskId,
    required TaskStatus status,
  }) async {
    final current = state.cast<TaskViewModel?>().firstWhere(
          (task) => task?.id == taskId,
          orElse: () => null,
        );
    if (current == null || current.status == status) return;

    final updated = TaskViewModel(
      id: current.id,
      title: current.title,
      status: status,
      dateLocal: current.dateLocal,
      startMin: current.startMin,
      endMin: current.endMin,
      tags: current.tags,
      totalSubtasks: current.totalSubtasks,
      doneSubtasks: current.doneSubtasks,
      hasAttachment: current.hasAttachment,
    );

    final next = [
      for (final task in state)
        if (task.id == taskId) updated else task,
    ];
    _sortTasks(next);
    state = next;

    final db = _ref.read(appDatabaseProvider);
    final dbTask = await (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
    final now = DateTime.now().toUtc();
    await _upsertTaskLocally(
      task: updated,
      now: now,
      enqueueOutbox: true,
      description: dbTask?.description,
    );
    await _attemptSync();
  }

  Future<void> deleteTask(String taskId) async {
    final exists = state.any((task) => task.id == taskId);
    if (!exists) return;

    state = [
      for (final task in state)
        if (task.id != taskId) task,
    ];

    final db = _ref.read(appDatabaseProvider);
    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      final subtasksForTask = await (db.select(db.subtasks)
            ..where((tbl) => tbl.taskId.equals(taskId)))
          .get();
      final subtaskIds = subtasksForTask.map((item) => item.id).toList();

      await (db.update(db.tasks)..where((tbl) => tbl.id.equals(taskId))).write(
        TasksCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (subtaskIds.isNotEmpty) {
        await (db.delete(db.reminders)
              ..where((tbl) =>
                  tbl.targetType.equals('subtask') &
                  tbl.targetId.isIn(subtaskIds)))
            .go();
      }

      await (db.delete(db.subtasks)..where((tbl) => tbl.taskId.equals(taskId)))
          .go();
      await (db.delete(db.attachments)
            ..where((tbl) => tbl.taskId.equals(taskId)))
          .go();
      await (db.delete(db.taskTags)..where((tbl) => tbl.taskId.equals(taskId)))
          .go();
      await (db.delete(db.reminders)
            ..where((tbl) =>
                tbl.targetType.equals('task') & tbl.targetId.equals(taskId)))
          .go();

      await db.into(db.outboxOps).insert(
            OutboxOpsCompanion.insert(
              id: _uuid.v4(),
              opId: _uuid.v4(),
              entity: 'task',
              action: 'delete',
              entityId: taskId,
              payloadJson: jsonEncode(<String, dynamic>{}),
              clientTs: now,
              retryCount: const Value(0),
            ),
          );
    });

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
  final Map<String, String> _holidayIdsByKey = <String, String>{};

  Future<void> _bootstrap() async {
    final db = _ref.read(appDatabaseProvider);
    final rows = await (db.select(db.holidays)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    final mapped = <DateTime, List<HolidayType>>{};
    _holidayIdsByKey.clear();
    for (final row in rows) {
      final type = _parseType(row.type);
      if (type == null) continue;
      final day = _parseDate(row.dateLocal);
      mapped.putIfAbsent(day, () => <HolidayType>[]).add(type);
      _holidayIdsByKey[_compoundKey(day, type)] = row.id;
    }
    state = _normalized(mapped);
    unawaited(refreshFromServer());
  }

  void replaceAll(Map<DateTime, List<HolidayType>> next) {
    state = _normalized(next);
  }

  Future<void> refreshFromServer() async {
    try {
      final items = await _fetchRemoteHolidays();
      await _replaceFromRemote(items);
    } catch (_) {
      // Keep local state on network failures.
    }
  }

  Future<void> saveAll(Map<DateTime, List<HolidayType>> next) async {
    final normalizedNext = _normalized(next);
    final currentEntries = _expand(state);
    final nextEntries = _expand(normalizedNext);

    final toRemove = currentEntries.difference(nextEntries);
    final toAdd = nextEntries.difference(currentEntries);

    try {
      await _ref.read(authedApiServiceProvider).run((accessToken) async {
        final api = _ref.read(apiClientProvider);
        for (final key in toRemove) {
          final id = _holidayIdsByKey[key];
          if (id == null || id.isEmpty) continue;
          await api.deleteHoliday(accessToken: accessToken, holidayId: id);
        }
        for (final key in toAdd) {
          final parsed = _parseCompoundKey(key);
          if (parsed == null) continue;
          await api.createHoliday(
            accessToken: accessToken,
            dateLocal: _dateString(parsed.day),
            type: parsed.type.name,
          );
        }
        return;
      });
      await refreshFromServer();
    } catch (_) {
      // Keep local draft in-memory even if save fails.
      state = normalizedNext;
    }
  }

  Future<void> clearTypeForYear({
    required int year,
    required HolidayType type,
  }) async {
    try {
      await _ref.read(authedApiServiceProvider).run((accessToken) async {
        await _ref.read(apiClientProvider).clearHolidayTypeForYear(
              accessToken: accessToken,
              year: year,
              type: type.name,
            );
        return;
      });
      await refreshFromServer();
    } catch (_) {
      final next = <DateTime, List<HolidayType>>{};
      for (final entry in state.entries) {
        if (entry.key.year != year) {
          next[entry.key] = [...entry.value];
          continue;
        }
        final values = [...entry.value]..remove(type);
        if (values.isNotEmpty) {
          next[entry.key] = values;
        }
      }
      state = _normalized(next);
    }
  }

  Future<List<HolidayItem>> _fetchRemoteHolidays() {
    return _ref.read(authedApiServiceProvider).run((accessToken) async {
      final response = await _ref
          .read(apiClientProvider)
          .listHolidays(accessToken: accessToken);
      final data = response.data;
      if (data is! List) return const <HolidayItem>[];
      return data
          .whereType<Map>()
          .map((item) => HolidayItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<void> _replaceFromRemote(List<HolidayItem> items) async {
    final mapped = <DateTime, List<HolidayType>>{};
    final ids = <String, String>{};
    for (final item in items) {
      final type = _parseType(item.type);
      if (type == null) continue;
      final day = _parseDate(item.dateLocal);
      mapped.putIfAbsent(day, () => <HolidayType>[]).add(type);
      ids[_compoundKey(day, type)] = item.id;
    }
    _holidayIdsByKey
      ..clear()
      ..addAll(ids);
    state = _normalized(mapped);
    await _replaceLocalRows(items);
  }

  Future<void> _replaceLocalRows(List<HolidayItem> items) async {
    final db = _ref.read(appDatabaseProvider);
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await db.delete(db.holidays).go();
      for (final item in items) {
        await db.into(db.holidays).insert(
              HolidaysCompanion.insert(
                id: item.id,
                dateLocal: item.dateLocal,
                type: item.type,
                createdAt: item.createdAt ?? now,
                updatedAt: item.updatedAt ?? now,
                label: Value(item.label),
                deletedAt: Value(item.deletedAt),
              ),
            );
      }
    });
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

  String _dateString(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  String _compoundKey(DateTime day, HolidayType type) {
    return '${_dateString(day)}|${type.name}';
  }

  _HolidayKey? _parseCompoundKey(String key) {
    final parts = key.split('|');
    if (parts.length != 2) return null;
    final day = _parseDate(parts[0]);
    final type = _parseType(parts[1]);
    if (type == null) return null;
    return _HolidayKey(day: day, type: type);
  }

  Map<DateTime, List<HolidayType>> _normalized(
      Map<DateTime, List<HolidayType>> source) {
    final normalized = <DateTime, List<HolidayType>>{};
    for (final entry in source.entries) {
      final key = DateTime(entry.key.year, entry.key.month, entry.key.day);
      final values = <HolidayType>[];
      for (final type in entry.value) {
        if (!values.contains(type)) values.add(type);
      }
      if (values.isNotEmpty) {
        normalized[key] = values;
      }
    }
    return normalized;
  }

  Set<String> _expand(Map<DateTime, List<HolidayType>> source) {
    final out = <String>{};
    for (final entry in source.entries) {
      for (final type in entry.value) {
        out.add(_compoundKey(entry.key, type));
      }
    }
    return out;
  }
}

class _HolidayKey {
  const _HolidayKey({
    required this.day,
    required this.type,
  });

  final DateTime day;
  final HolidayType type;
}
