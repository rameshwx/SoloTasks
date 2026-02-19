import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_palette.dart';
import 'glass_container.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.compact = false,
  });

  final TaskViewModel task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      borderRadius: 24,
      padding: EdgeInsets.all(compact ? 12 : 14),
      tint: theme.taskCardTint,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/task/${task.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmt(task.startMin)} - ${_fmt(task.endMin)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.subduedText),
                      ),
                    ],
                  ),
                ),
                _statusChip(task.status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in task.tags)
                  Chip(
                    label: Text(tag),
                    labelStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    visualDensity: VisualDensity.compact,
                  ),
                if (task.hasAttachment)
                  const Chip(
                    avatar: Icon(Icons.attach_file_rounded, size: 14),
                    label: Text('Attachment'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (task.hasSubtasks) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (task.progressPercent ?? 0) / 100,
                        minHeight: 7,
                        backgroundColor: theme.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                        color: AppPalette.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (task.progressPercent ?? 0) / 100,
                          strokeWidth: 3.2,
                          backgroundColor: theme.isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.10),
                          color: AppPalette.teal,
                        ),
                        Text(
                          '${task.doneSubtasks}/${task.totalSubtasks}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(TaskStatus status) {
    final (label, background, foreground) = switch (status) {
      TaskStatus.todo => (
          'To Do',
          AppPalette.teal.withValues(alpha: 0.12),
          AppPalette.teal
        ),
      TaskStatus.inProgress => (
          'In Progress',
          AppPalette.success.withValues(alpha: 0.16),
          AppPalette.success
        ),
      TaskStatus.blocked => (
          'Blocked',
          AppPalette.danger.withValues(alpha: 0.18),
          AppPalette.danger
        ),
      TaskStatus.done => (
          'Done',
          AppPalette.success.withValues(alpha: 0.16),
          AppPalette.success
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static String _fmt(int totalMin) {
    final hour = totalMin ~/ 60;
    final minute = totalMin % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }
}
