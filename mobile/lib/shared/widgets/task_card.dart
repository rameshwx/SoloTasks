import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_models.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final TaskViewModel task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/task/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('${_fmt(task.startMin)} - ${_fmt(task.endMin)}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in task.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact),
                  if (task.hasAttachment) const Chip(label: Text('Attachment'), visualDensity: VisualDensity.compact),
                ],
              ),
              if (task.hasSubtasks) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: (task.progressPercent ?? 0) / 100),
                const SizedBox(height: 4),
                Text('${task.progressPercent!.toStringAsFixed(0)}% complete'),
              ],
            ],
          ),
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
