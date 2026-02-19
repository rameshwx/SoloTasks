import 'package:flutter_test/flutter_test.dart';
import 'package:solotasks/core/logic/task_rules.dart';

void main() {
  group('Progress calc', () {
    test('returns null when no subtasks', () {
      expect(computeSubtaskProgress(done: 0, total: 0), isNull);
    });

    test('computes ratio correctly', () {
      expect(computeSubtaskProgress(done: 2, total: 4), 50);
    });
  });

  group('Scheduling constraints', () {
    test('accepts valid same-day window', () {
      expect(() => validateTaskWindow(startMin: 540, endMin: 600),
          returnsNormally);
    });

    test('rejects midnight crossing task', () {
      expect(
        () => validateTaskWindow(startMin: 1430, durationMin: 30),
        throwsArgumentError,
      );
    });
  });

  group('Series generation', () {
    test('creates N linked daily tasks', () {
      final series = buildSeries(
        title: 'Deep Work',
        startDate: DateTime(2026, 2, 19),
        days: 3,
        startMin: 540,
        endMin: 600,
        seriesId: 'series-1',
      );
      expect(series.length, 3);
      expect(series.first.seriesIndex, 1);
      expect(series.last.seriesIndex, 3);
      expect(series.last.seriesTotal, 3);
    });
  });

  group('Sync merge', () {
    test('delete wins over active record', () {
      final local = [
        MergeRecord(
          id: 'a',
          updatedAt: DateTime(2026, 2, 19, 10),
          deleted: false,
          payload: const {'title': 'task'},
        ),
      ];
      final remote = [
        MergeRecord(
          id: 'a',
          updatedAt: DateTime(2026, 2, 19, 9),
          deleted: true,
          payload: const {},
        ),
      ];

      final result = mergeLww(local: local, remote: remote);
      expect(result['a']!.deleted, isTrue);
    });
  });
}
