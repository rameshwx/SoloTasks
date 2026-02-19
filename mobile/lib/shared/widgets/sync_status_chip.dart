import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sync_provider.dart';
import '../../core/theme/app_palette.dart';
import 'glass_container.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final (label, color) = switch (status) {
      SyncStatus.synced => ('Synced', AppPalette.success),
      SyncStatus.syncing => ('Syncing', AppPalette.teal),
      SyncStatus.offline => ('Offline', const Color(0xFFF59E0B)),
      SyncStatus.error => ('Error', AppPalette.danger),
    };

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
