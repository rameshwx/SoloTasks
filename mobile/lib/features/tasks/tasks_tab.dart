import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/time_format.dart';
import '../../core/models/app_models.dart';
import '../../core/models/remote_models.dart';
import '../../core/models/user_preferences.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../core/providers/subtask_provider.dart';
import '../../core/providers/tag_provider.dart';
import '../../core/providers/task_tag_provider.dart';
import '../../core/providers/user_preferences_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'tag_manager_sheet.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  final _searchCtrl = TextEditingController();

  bool _hasAttachments = false;
  String? _selectedTagName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final tagsState = ref.watch(tagControllerProvider);
    final holidayMap = ref.watch(holidayDatesProvider);
    final prefs = ref.watch(userPreferencesProvider).valueOrNull;
    final query = _searchCtrl.text.trim().toLowerCase();
    final hideTasksOnHolidays =
        prefs?.holidayPrefs.hideTasksOnHolidays ?? false;
    final taskTagNamesById = <String, List<String>>{
      for (final task in tasks)
        task.id: () {
          final remote =
              ref.watch(taskTagControllerProvider(task.id)).valueOrNull;
          if (remote == null || remote.isEmpty) return task.tags;
          return remote.map((tag) => tag.name).toList();
        }(),
    };

    final filtered = tasks.where((task) {
      if (hideTasksOnHolidays &&
          (holidayMap[DateTime(
                    task.dateLocal.year,
                    task.dateLocal.month,
                    task.dateLocal.day,
                  )] ??
                  const [])
              .isNotEmpty) {
        return false;
      }
      final matchesSearch = task.title.toLowerCase().contains(query);
      final matchesAttachment = !_hasAttachments || task.hasAttachment;
      final taskTags = taskTagNamesById[task.id] ?? task.tags;
      final matchesTag = _selectedTagName == null
          ? true
          : taskTags.any((tag) => tag == _selectedTagName);
      return matchesSearch && matchesAttachment && matchesTag;
    }).toList();

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 146),
            children: [
              _header(context),
              const SizedBox(height: 14),
              _filterRow(context, tagsState),
              const SizedBox(height: 20),
              Text(
                'Recent Results',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < filtered.length; i++) ...[
                _ResultTaskTile(
                  task: filtered[i],
                  displayTags: taskTagNamesById[filtered[i].id] ?? const [],
                )
                    .animate(delay: (i * 55).ms)
                    .fadeIn(duration: 240.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return GlassContainer(
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Tasks',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              GlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.person, color: AppPalette.teal),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _openTagManager,
                icon: const Icon(Icons.sell_rounded),
                label: const Text('Tags'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search tasks, events, tags...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _searchCtrl.clear()),
                icon: const Icon(Icons.mic_none_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(BuildContext context, AsyncValue<List<TagItem>> tagsState) {
    final tagLabel =
        _selectedTagName == null ? 'Tags' : 'Tag: $_selectedTagName';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipBtn(title: 'Status', onTap: () {}),
          const SizedBox(width: 10),
          _FilterChipBtn(
            title: tagLabel,
            onTap: () => _openTagPicker(tagsState),
          ),
          if (_selectedTagName != null) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => setState(() => _selectedTagName = null),
              icon: const Icon(Icons.clear_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(width: 10),
          _FilterChipBtn(title: 'Date Range', onTap: () {}),
          const SizedBox(width: 10),
          _FilterChipBtn(
            title: _hasAttachments ? 'Attachments: On' : 'Attachments',
            trailing: _hasAttachments
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            onTap: () => setState(() => _hasAttachments = !_hasAttachments),
          ),
        ],
      ),
    );
  }

  Future<void> _openTagManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TagManagerSheet(),
    );
  }

  Future<void> _openTagPicker(AsyncValue<List<TagItem>> tagsState) async {
    final tags = tagsState.valueOrNull;
    if (tags == null || tags.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No tags yet. Use Manage Tags to add one.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text('Filter by Tag'),
                  leading: Icon(Icons.sell_rounded, color: AppPalette.teal),
                ),
                ListTile(
                  title: const Text('All Tags'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
                for (final tag in tags)
                  ListTile(
                    title: Text(tag.name),
                    onTap: () => Navigator.of(context).pop(tag.name),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _selectedTagName = selected);
  }
}

class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({
    required this.title,
    this.trailing = Icons.expand_more,
    required this.onTap,
  });

  final String title;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Icon(trailing, size: 18, color: Theme.of(context).subduedText),
          ],
        ),
      ),
    );
  }
}

class _ResultTaskTile extends ConsumerWidget {
  const _ResultTaskTile({
    required this.task,
    required this.displayTags,
  });

  final TaskViewModel task;
  final List<String> displayTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksState = ref.watch(taskSubtaskControllerProvider(task.id));
    final timeFormat = ref
            .watch(userPreferencesProvider)
            .valueOrNull
            ?.calendarPrefs
            .timeFormat ??
        UserTimeFormat.system;
    final subtasks = subtasksState.valueOrNull;
    final totalSubtasks = subtasks?.length ?? task.totalSubtasks;
    final doneSubtasks = subtasks?.where((subtask) => subtask.isDone).length ??
        task.doneSubtasks;
    final hasSubtasks = totalSubtasks > 0;
    final percent =
        hasSubtasks ? ((doneSubtasks / totalSubtasks) * 100).round() : 0;
    final isDone = task.status == TaskStatus.done;

    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _toggleComplete(ref, context, isDone),
            icon: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? AppPalette.success : const Color(0xFF738B96),
              size: 30,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Theme.of(context).subduedText : null,
                        )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: Theme.of(context).subduedText),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(context, task.startMin, timeFormat),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: task.status == TaskStatus.blocked
                                ? AppPalette.danger
                                : AppPalette.teal,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Theme.of(context).subduedText,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Icon(Icons.folder_outlined,
                        size: 16, color: Theme.of(context).subduedText),
                    const SizedBox(width: 4),
                    Text(displayTags.isEmpty ? 'General' : _tagSummary(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Theme.of(context).subduedText)),
                  ],
                ),
                if (hasSubtasks) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tasks $doneSubtasks/$totalSubtasks : $percent% completed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).subduedText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (task.hasAttachment)
            Icon(Icons.attach_file_rounded,
                color: Theme.of(context).subduedText)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: AppPalette.success.withValues(alpha: 0.35)),
              ),
              child: Text(
                displayTags.isEmpty ? 'General' : _tagSummary(),
                style: const TextStyle(
                  color: AppPalette.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _tagSummary() {
    if (displayTags.isEmpty) return 'General';
    if (displayTags.length == 1) return displayTags.first;
    return '${displayTags.first} +${displayTags.length - 1}';
  }

  Future<void> _toggleComplete(
    WidgetRef ref,
    BuildContext context,
    bool currentlyDone,
  ) async {
    final markDone = !currentlyDone;
    try {
      await ref.read(taskListProvider.notifier).setTaskStatus(
            taskId: task.id,
            status: markDone ? TaskStatus.done : TaskStatus.todo,
          );
      final subtaskCtrl =
          ref.read(taskSubtaskControllerProvider(task.id).notifier);
      if (markDone) {
        await subtaskCtrl.markAllDone();
      } else {
        await subtaskCtrl.markAllUndone();
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    }
  }

  String _formatTime(
    BuildContext context,
    int totalMin,
    UserTimeFormat timeFormat,
  ) {
    return 'Today ${formatMinutesForPreference(context, totalMin, timeFormat)}';
  }
}
