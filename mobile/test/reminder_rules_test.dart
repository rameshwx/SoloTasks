import 'package:flutter_test/flutter_test.dart';
import 'package:solotasks/core/logic/reminder_rules.dart';
import 'package:solotasks/core/models/app_models.dart';
import 'package:solotasks/core/models/remote_models.dart';

void main() {
  group('Reminder timing', () {
    final task = TaskViewModel(
      id: 'task-1',
      title: 'Deep Work',
      status: TaskStatus.todo,
      dateLocal: DateTime(2026, 3, 2),
      startMin: 9 * 60,
      endMin: 10 * 60,
      tags: const <String>[],
      totalSubtasks: 0,
      doneSubtasks: 0,
      hasAttachment: false,
    );

    test('uses absolute UTC trigger as-is', () {
      final reminder = ReminderItem(
        id: 'r-1',
        targetType: 'task',
        targetId: 'task-1',
        triggerAtUtc: DateTime.utc(2026, 3, 2, 8, 45),
      );

      expect(
        resolveReminderTriggerUtc(task: task, reminder: reminder),
        DateTime.utc(2026, 3, 2, 8, 45),
      );
    });

    test('converts relative reminders to UTC before task start', () {
      final reminder = ReminderItem(
        id: 'r-2',
        targetType: 'task',
        targetId: 'task-1',
        offsetMinFromTaskStart: 15,
      );

      final expected = DateTime(2026, 3, 2, 8, 45).toUtc();
      expect(
        resolveReminderTriggerUtc(task: task, reminder: reminder),
        expected,
      );
    });

    test('late relative reminders fall back to immediate scheduling', () {
      final reminder = ReminderItem(
        id: 'r-3',
        targetType: 'task',
        targetId: 'task-1',
        offsetMinFromTaskStart: 5,
      );

      final nowUtc =
          resolveTaskStartUtc(task).subtract(const Duration(minutes: 2));
      expect(
        resolveReminderScheduleUtc(
          task: task,
          reminder: reminder,
          nowUtc: nowUtc,
        ),
        nowUtc.add(const Duration(seconds: 3)),
      );
    });

    test('only schedules future reminders', () {
      expect(
        shouldScheduleReminder(
          triggerAtUtc: DateTime.utc(2026, 3, 2, 9, 0),
          nowUtc: DateTime.utc(2026, 3, 2, 8, 59),
        ),
        isTrue,
      );

      expect(
        shouldScheduleReminder(
          triggerAtUtc: DateTime.utc(2026, 3, 2, 9, 0),
          nowUtc: DateTime.utc(2026, 3, 2, 9, 0),
        ),
        isFalse,
      );
    });
  });
}
