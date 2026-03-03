import '../models/app_models.dart';
import '../models/remote_models.dart';

DateTime resolveTaskStartUtc(TaskViewModel task) {
  return DateTime(
    task.dateLocal.year,
    task.dateLocal.month,
    task.dateLocal.day,
    task.startMin ~/ 60,
    task.startMin % 60,
  ).toUtc();
}

DateTime? resolveReminderTriggerUtc({
  required TaskViewModel task,
  required ReminderItem reminder,
}) {
  final absolute = reminder.triggerAtUtc;
  if (absolute != null) {
    return absolute.toUtc();
  }

  final offset = reminder.offsetMinFromTaskStart;
  if (offset == null) {
    return null;
  }

  return resolveTaskStartUtc(task).subtract(Duration(minutes: offset));
}

DateTime? resolveReminderScheduleUtc({
  required TaskViewModel task,
  required ReminderItem reminder,
  DateTime? nowUtc,
  Duration lateRelativeFallback = const Duration(seconds: 3),
}) {
  final triggerAtUtc =
      resolveReminderTriggerUtc(task: task, reminder: reminder);
  if (triggerAtUtc == null) {
    return null;
  }

  final now = nowUtc ?? DateTime.now().toUtc();
  if (triggerAtUtc.isAfter(now)) {
    return triggerAtUtc;
  }

  if (!reminder.isRelative) {
    return null;
  }

  final taskStartUtc = resolveTaskStartUtc(task);
  if (!taskStartUtc.isAfter(now)) {
    return null;
  }

  return now.add(lateRelativeFallback);
}

bool shouldScheduleReminder({
  required DateTime triggerAtUtc,
  DateTime? nowUtc,
}) {
  final now = nowUtc ?? DateTime.now().toUtc();
  return triggerAtUtc.isAfter(now);
}
