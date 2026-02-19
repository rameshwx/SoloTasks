import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/mock_data_provider.dart';
import '../../shared/widgets/task_card.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  final _searchCtrl = TextEditingController();
  bool _hasAttachments = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(query);
      final matchesAttachment = !_hasAttachments || task.hasAttachment;
      return matchesSearch && matchesAttachment;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(_searchCtrl.clear),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Has attachments'),
                selected: _hasAttachments,
                onSelected: (selected) => setState(() => _hasAttachments = selected),
              ),
              const Chip(label: Text('Smart Lists')), 
              const Chip(label: Text('Tags')), 
              const Chip(label: Text('Status')), 
            ],
          ),
          const SizedBox(height: 16),
          for (final task in filtered) ...[
            TaskCard(task: task),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
