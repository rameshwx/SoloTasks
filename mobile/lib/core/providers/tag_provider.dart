import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/remote_models.dart';
import '../services/authed_api_service.dart';
import 'api_provider.dart';

final tagControllerProvider =
    StateNotifierProvider<TagController, AsyncValue<List<TagItem>>>((ref) {
  return TagController(ref);
});

class TagController extends StateNotifier<AsyncValue<List<TagItem>>> {
  TagController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchTags();
      state = AsyncValue.data(list);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTag(String name, {String? color}) async {
    if (name.trim().isEmpty) return;
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).createTag(
            accessToken: accessToken,
            name: name.trim(),
            color: color,
          );
      return;
    });
    await load();
  }

  Future<void> renameTag(String tagId, String name) async {
    if (name.trim().isEmpty) return;
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).updateTag(
            accessToken: accessToken,
            tagId: tagId,
            name: name.trim(),
          );
      return;
    });
    await load();
  }

  Future<void> deleteTag(String tagId) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).deleteTag(
            accessToken: accessToken,
            tagId: tagId,
          );
      return;
    });
    await load();
  }

  Future<List<TagItem>> _fetchTags() {
    return _ref.read(authedApiServiceProvider).run((accessToken) async {
      final response =
          await _ref.read(apiClientProvider).listTags(accessToken: accessToken);
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
