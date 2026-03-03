import 'dart:math';

import '../models/app_models.dart';

void validateTaskWindow({
  required int startMin,
  int? endMin,
  int? durationMin,
}) {
  if (startMin < 0 || startMin >= 1440) {
    throw ArgumentError('startMin must be within 0..1439');
  }
  if (endMin == null && durationMin == null) {
    throw ArgumentError('Either endMin or durationMin is required');
  }
  if (endMin != null) {
    if (endMin <= startMin || endMin > 1440) {
      throw ArgumentError('Task cannot span midnight');
    }
  }
  if (durationMin != null) {
    if (durationMin <= 0 || startMin + durationMin > 1440) {
      throw ArgumentError('Task cannot span midnight');
    }
  }
}

double? computeSubtaskProgress({
  required int done,
  required int total,
}) {
  if (total <= 0) return null;
  return (done / total) * 100;
}

bool shouldAutoCompleteParentTask({
  required int done,
  required int total,
  required TaskStatus currentStatus,
}) {
  if (total <= 0) return false;
  if (done != total) return false;
  return currentStatus != TaskStatus.done;
}

String nextOrderKey(String? prev, String? next) {
  if (prev == null && next == null) return 'm';
  if (prev == null) return '${next!}0';
  if (next == null) return '${prev}z';
  return '${prev.substring(0, min(prev.length, 3))}m';
}

class SeriesTaskSpec {
  SeriesTaskSpec({
    required this.title,
    required this.date,
    required this.startMin,
    required this.endMin,
    required this.seriesId,
    required this.seriesIndex,
    required this.seriesTotal,
  });

  final String title;
  final DateTime date;
  final int startMin;
  final int endMin;
  final String seriesId;
  final int seriesIndex;
  final int seriesTotal;
}

List<SeriesTaskSpec> buildSeries({
  required String title,
  required DateTime startDate,
  required int days,
  required int startMin,
  required int endMin,
  required String seriesId,
}) {
  validateTaskWindow(startMin: startMin, endMin: endMin);
  if (days <= 0) throw ArgumentError('days must be > 0');

  return List.generate(days, (index) {
    return SeriesTaskSpec(
      title: title,
      date: DateTime(startDate.year, startDate.month, startDate.day + index),
      startMin: startMin,
      endMin: endMin,
      seriesId: seriesId,
      seriesIndex: index + 1,
      seriesTotal: days,
    );
  });
}

class MergeRecord {
  MergeRecord({
    required this.id,
    required this.updatedAt,
    required this.deleted,
    required this.payload,
  });

  final String id;
  final DateTime updatedAt;
  final bool deleted;
  final Map<String, Object?> payload;
}

Map<String, MergeRecord> mergeLww({
  required List<MergeRecord> local,
  required List<MergeRecord> remote,
}) {
  final merged = <String, MergeRecord>{
    for (final record in local) record.id: record,
  };

  for (final record in remote) {
    final current = merged[record.id];
    if (current == null) {
      merged[record.id] = record;
      continue;
    }

    if (record.deleted && !current.deleted) {
      merged[record.id] = record;
      continue;
    }

    if (record.updatedAt.isAfter(current.updatedAt)) {
      merged[record.id] = record;
    }
  }

  return merged;
}

bool shouldShowProgress(TaskViewModel task) => task.hasSubtasks;
