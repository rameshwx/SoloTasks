import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/remote_models.dart';
import '../services/authed_api_service.dart';
import 'api_provider.dart';

final taskAttachmentControllerProvider = StateNotifierProvider.family<
    TaskAttachmentController, AsyncValue<List<AttachmentItem>>, String>(
  (ref, taskId) => TaskAttachmentController(ref, taskId),
);

class TaskAttachmentController
    extends StateNotifier<AsyncValue<List<AttachmentItem>>> {
  TaskAttachmentController(this._ref, this.taskId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final String taskId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _fetchAttachments();
      state = AsyncValue.data(list);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addFromPicker() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Selected file has no readable bytes.');
    }
    final fileName = file.name;
    final mimeType = _guessMimeType(fileName);

    await _uploadFile(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
    );
    await load();
  }

  Future<void> deleteAttachment(String attachmentId) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      await _ref.read(apiClientProvider).deleteAttachment(
            accessToken: accessToken,
            attachmentId: attachmentId,
          );
      return;
    });
    await load();
  }

  String downloadUrl(String attachmentId) {
    return _ref.read(apiClientProvider).attachmentDownloadUrl(attachmentId);
  }

  Future<void> _uploadFile({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    await _ref.read(authedApiServiceProvider).run((accessToken) async {
      final initResponse = await _ref.read(apiClientProvider).uploadInit(
            accessToken: accessToken,
            taskId: taskId,
            fileName: fileName,
            mimeType: mimeType,
            size: bytes.lengthInBytes,
          );
      final initBody = _asMap(initResponse.data);
      final init = UploadInitItem.fromJson(initBody);
      if (init.uploadUrl.isEmpty) {
        throw Exception('Upload URL missing from server response.');
      }

      await _ref.read(apiClientProvider).uploadAttachmentBytes(
            accessToken: accessToken,
            uploadUrl: init.uploadUrl,
            method: init.method,
            headers: init.headers,
            bytes: bytes,
          );
      return;
    });
  }

  Future<List<AttachmentItem>> _fetchAttachments() {
    return _ref.read(authedApiServiceProvider).run((accessToken) async {
      final response = await _ref.read(apiClientProvider).listTaskAttachments(
            accessToken: accessToken,
            taskId: taskId,
          );
      final data = response.data;
      if (data is! List) return const <AttachmentItem>[];
      return data
          .whereType<Map>()
          .map((item) => AttachmentItem.fromJson(item.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}
