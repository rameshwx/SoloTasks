import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/remote_models.dart';
import '../services/authed_api_service.dart';
import 'api_provider.dart';

final taskReminderControllerProvider = StateNotifierProvider.family<
    TaskReminderController,
    AsyncValue<List<ReminderItem>>,
    String>((ref, taskId) {
  return TaskReminderController(ref, taskId);
});

class TaskReminderController
    extends StateNotifier<AsyncValue<List<ReminderItem>>> {
  TaskReminderController(this._ref, this.taskId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final String taskId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchTaskReminders();
      state = AsyncValue.data(list);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createRelative(int offsetMinFromTaskStart) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).createReminder(
            accessToken: accessToken,
            targetType: 'task',
            targetId: taskId,
            offsetMinFromTaskStart: offsetMinFromTaskStart,
          );
      return;
    });
    await load();
  }

  Future<void> createAbsolute(DateTime triggerAtUtc) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).createReminder(
            accessToken: accessToken,
            targetType: 'task',
            targetId: taskId,
            triggerAtUtc: triggerAtUtc,
          );
      return;
    });
    await load();
  }

  Future<void> updateRelative({
    required String reminderId,
    required int offsetMinFromTaskStart,
  }) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).updateReminder(
            accessToken: accessToken,
            reminderId: reminderId,
            offsetMinFromTaskStart: offsetMinFromTaskStart,
          );
      return;
    });
    await load();
  }

  Future<void> deleteReminder(String reminderId) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).deleteReminder(
            accessToken: accessToken,
            reminderId: reminderId,
          );
      return;
    });
    await load();
  }

  Future<List<ReminderItem>> _fetchTaskReminders() {
    return _ref.read(authedApiServiceProvider).run((accessToken) async {
      final response = await _ref
          .read(apiClientProvider)
          .listReminders(accessToken: accessToken);
      final data = response.data;
      if (data is! List) return const <ReminderItem>[];
      final all = data
          .whereType<Map>()
          .map((item) => ReminderItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      final filtered = all
          .where((item) => item.targetType == 'task' && item.targetId == taskId)
          .toList();
      filtered.sort((a, b) {
        final ao = a.offsetMinFromTaskStart ?? 100000;
        final bo = b.offsetMinFromTaskStart ?? 100000;
        if (ao != bo) return ao.compareTo(bo);
        final at = a.triggerAtUtc?.millisecondsSinceEpoch ?? 1000000000;
        final bt = b.triggerAtUtc?.millisecondsSinceEpoch ?? 1000000000;
        return at.compareTo(bt);
      });
      return filtered;
    });
  }
}
