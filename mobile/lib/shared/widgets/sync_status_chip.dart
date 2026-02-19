import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sync_provider.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final (label, color) = switch (status) {
      SyncStatus.synced => ('Synced', Colors.green),
      SyncStatus.syncing => ('Syncing', Colors.blue),
      SyncStatus.offline => ('Offline', Colors.orange),
      SyncStatus.error => ('Error', Colors.red),
    };

    return Chip(
      label: Text(label),
      avatar: CircleAvatar(backgroundColor: color, radius: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
