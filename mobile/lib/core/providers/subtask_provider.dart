import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/remote_models.dart';
import '../services/authed_api_service.dart';
import 'api_provider.dart';

final taskSubtaskControllerProvider = StateNotifierProvider.family<
    TaskSubtaskController, AsyncValue<List<SubtaskItem>>, String>(
  (ref, taskId) => TaskSubtaskController(ref, taskId),
);

class TaskSubtaskController
    extends StateNotifier<AsyncValue<List<SubtaskItem>>> {
  TaskSubtaskController(this._ref, this.taskId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final String taskId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final subtasks = await _fetchSubtasks();
      state = AsyncValue.data(subtasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSubtask({
    required String title,
    String? note,
  }) async {
    final nowKey = DateTime.now().microsecondsSinceEpoch.toString();
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).createTaskSubtask(
            accessToken: accessToken,
            taskId: taskId,
            title: title,
            orderKey: nowKey,
            note: note,
          );
      return;
    });
    await load();
  }

  Future<void> updateSubtask({
    required String subtaskId,
    String? title,
    bool? isDone,
    String? note,
    String? orderKey,
  }) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).updateTaskSubtask(
            accessToken: accessToken,
            taskId: taskId,
            subtaskId: subtaskId,
            title: title,
            isDone: isDone,
            note: note,
            orderKey: orderKey,
          );
      return;
    });
    await load();
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).deleteTaskSubtask(
            accessToken: accessToken,
            taskId: taskId,
            subtaskId: subtaskId,
          );
      return;
    });
    await load();
  }

  Future<void> markAllDone() async {
    final current = state.valueOrNull ?? await _fetchSubtasks();
    final pending = current.where((subtask) => !subtask.isDone).toList();
    if (pending.isEmpty) return;

    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      for (final subtask in pending) {
        await _ref.read(apiClientProvider).updateTaskSubtask(
              accessToken: accessToken,
              taskId: taskId,
              subtaskId: subtask.id,
              isDone: true,
            );
      }
      return;
    });
    await load();
  }

  Future<List<SubtaskItem>> _fetchSubtasks() {
    return _ref.read(authedApiServiceProvider).run((accessToken) async {
      final response = await _ref.read(apiClientProvider).listTaskSubtasks(
            accessToken: accessToken,
            taskId: taskId,
          );
      final data = response.data;
      if (data is! List) return const <SubtaskItem>[];
      final items = data
          .whereType<Map>()
          .map((item) => SubtaskItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      items.sort((a, b) => a.orderKey.compareTo(b.orderKey));
      return items;
    });
  }
}
