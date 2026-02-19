class TagItem {
  TagItem({
    required this.id,
    required this.name,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TagItem.fromJson(Map<String, dynamic> json) {
    return TagItem(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class SubtaskItem {
  SubtaskItem({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.orderKey,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final String orderKey;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubtaskItem.fromJson(Map<String, dynamic> json) {
    return SubtaskItem(
      id: json['id'].toString(),
      taskId: (json['task_id'] ?? json['taskId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      isDone: _parseBool(json['is_done'] ?? json['isDone']) ?? false,
      orderKey: (json['order_key'] ?? json['orderKey'] ?? '').toString(),
      note: (json['note'])?.toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class ReminderItem {
  ReminderItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.triggerAtUtc,
    this.offsetMinFromTaskStart,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final DateTime? triggerAtUtc;
  final int? offsetMinFromTaskStart;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRelative => offsetMinFromTaskStart != null;

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'].toString(),
      targetType: (json['target_type'] ?? json['targetType'] ?? '').toString(),
      targetId: (json['target_id'] ?? json['targetId'] ?? '').toString(),
      triggerAtUtc:
          _parseDateTime(json['trigger_at_utc'] ?? json['triggerAtUtc']),
      offsetMinFromTaskStart: _parseInt(
        json['offset_min_from_task_start'] ?? json['offsetMinFromTaskStart'],
      ),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class AttachmentItem {
  AttachmentItem({
    required this.id,
    required this.taskId,
    required this.type,
    required this.name,
    required this.size,
    required this.remoteKey,
    this.cachedPath,
    required this.keepOffline,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String type;
  final String name;
  final int size;
  final String remoteKey;
  final String? cachedPath;
  final bool keepOffline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPdf => type.toLowerCase() == 'pdf';
  bool get isImage => type.toLowerCase() == 'image';

  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: json['id'].toString(),
      taskId: (json['task_id'] ?? json['taskId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      size: _parseInt(json['size']) ?? 0,
      remoteKey: (json['remote_key'] ?? json['remoteKey'] ?? '').toString(),
      cachedPath: (json['cached_path'] ?? json['cachedPath'])?.toString(),
      keepOffline:
          (json['keep_offline'] ?? json['keepOffline'] ?? false) == true,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }
}

class UploadInitItem {
  UploadInitItem({
    required this.attachmentId,
    required this.uploadUrl,
    required this.remoteKey,
    required this.method,
    required this.headers,
  });

  final String attachmentId;
  final String uploadUrl;
  final String remoteKey;
  final String method;
  final Map<String, String> headers;

  factory UploadInitItem.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    final headers = <String, String>{};
    if (headersRaw is Map) {
      for (final entry in headersRaw.entries) {
        headers[entry.key.toString()] = entry.value.toString();
      }
    }
    return UploadInitItem(
      attachmentId:
          (json['attachmentId'] ?? json['attachment_id'] ?? '').toString(),
      uploadUrl: (json['uploadUrl'] ?? json['upload_url'] ?? '').toString(),
      remoteKey: (json['remoteKey'] ?? json['remote_key'] ?? '').toString(),
      method: (json['method'] ?? 'PUT').toString(),
      headers: headers,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}
