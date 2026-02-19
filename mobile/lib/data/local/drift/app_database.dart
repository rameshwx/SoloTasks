import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()();
  TextColumn get dateLocal => text()();
  IntColumn get startMin => integer()();
  IntColumn get endMin => integer().nullable()();
  IntColumn get durationMin => integer().nullable()();
  TextColumn get seriesId => text().nullable()();
  IntColumn get seriesIndex => integer().nullable()();
  IntColumn get seriesTotal => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get orderKey => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TaskTags extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get triggerAtUtc => dateTime().nullable()();
  IntColumn get offsetMinFromTaskStart => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  IntColumn get size => integer()();
  TextColumn get remoteKey => text()();
  TextColumn get cachedPath => text().nullable()();
  BoolColumn get keepOffline => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Holidays extends Table {
  TextColumn get id => text()();
  TextColumn get dateLocal => text()();
  TextColumn get type => text()();
  TextColumn get label => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OutboxOps extends Table {
  TextColumn get id => text()();
  TextColumn get opId => text()();
  TextColumn get entity => text()();
  TextColumn get action => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get clientTs => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncState extends Table {
  TextColumn get id => text()();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SmartLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get filtersJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Tasks,
    Subtasks,
    Tags,
    TaskTags,
    Reminders,
    Attachments,
    Holidays,
    OutboxOps,
    SyncState,
    Settings,
    SmartLists,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Task>> listTasksForDay(DateTime day) {
    final dayKey = _dayString(day);
    return (select(tasks)
          ..where(
              (tbl) => tbl.dateLocal.equals(dayKey) & tbl.deletedAt.isNull()))
        .get();
  }

  Future<void> upsertHoliday({
    required String id,
    required String dateLocal,
    required String type,
    String? label,
    required DateTime now,
  }) {
    return into(holidays).insertOnConflictUpdate(
      HolidaysCompanion(
        id: Value(id),
        dateLocal: Value(dateLocal),
        type: Value(type),
        label: Value(label),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  String _dayString(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'solotasks.sqlite'));
    return NativeDatabase(file);
  });
}
