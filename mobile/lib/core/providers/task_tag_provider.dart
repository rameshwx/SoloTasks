import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/remote_models.dart';
import '../services/authed_api_service.dart';
import 'api_provider.dart';

final taskTagControllerProvider = StateNotifierProvider.family<
    TaskTagController, AsyncValue<List<TagItem>>, String>((ref, taskId) {
  return TaskTagController(ref, taskId);
});

class TaskTagController extends StateNotifier<AsyncValue<List<TagItem>>> {
  TaskTagController(this._ref, this.taskId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final String taskId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchTaskTags();
      state = AsyncValue.data(list);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> replaceTagIds(List<String> tagIds) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).replaceTaskTags(
            accessToken: accessToken,
            taskId: taskId,
            tagIds: tagIds,
          );
      return;
    });
    await load();
  }

  Future<List<TagItem>> _fetchTaskTags() {
    return _ref.read(authedApiServiceProvider).run((accessToken) async {
      final response = await _ref.read(apiClientProvider).listTaskTags(
            accessToken: accessToken,
            taskId: taskId,
          );
      final data = response.data;
      if (data is! List) return const <TagItem>[];
      return data
          .whereType<Map>()
          .map((item) => TagItem.fromJson(item.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }
}
