import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/time_format.dart';
import '../../core/models/app_models.dart';
import '../../core/models/remote_models.dart';
import '../../core/models/user_preferences.dart';
import '../../core/providers/attachment_provider.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../core/providers/reminder_provider.dart';
import '../../core/providers/subtask_provider.dart';
import '../../core/providers/tag_provider.dart';
import '../../core/providers/task_tag_provider.dart';
import '../../core/providers/user_preferences_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _busyAttachments = false;
  bool _busyReminders = false;
  bool _busySubtasks = false;
  bool _busyTaskTags = false;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final task = tasks.cast<TaskViewModel?>().firstWhere(
          (item) => item?.id == widget.taskId,
          orElse: () => null,
        );
    final attachmentsState =
        ref.watch(taskAttachmentControllerProvider(widget.taskId));
    final remindersState =
        ref.watch(taskReminderControllerProvider(widget.taskId));
    final subtasksState =
        ref.watch(taskSubtaskControllerProvider(widget.taskId));
    final taskTagsState = ref.watch(taskTagControllerProvider(widget.taskId));
    final allTagsState = ref.watch(tagControllerProvider);
    final timeFormat = ref
            .watch(userPreferencesProvider)
            .valueOrNull
            ?.calendarPrefs
            .timeFormat ??
        UserTimeFormat.system;

    if (task == null) {
      return Scaffold(
        body: AuroraBackground(
          child: SafeArea(
            child: Center(
              child: GlassContainer(
                borderRadius: 24,
                child: const Text('Task not found'),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 128),
            children: [
              _header(context),
              const SizedBox(height: 14),
              _heroCard(
                context,
                task,
                taskTagsState.valueOrNull ?? const <TagItem>[],
                timeFormat,
              ),
              const SizedBox(height: 18),
              _taskTagSection(context, taskTagsState, allTagsState),
              const SizedBox(height: 18),
              _subtaskSection(context, task, subtasksState),
              const SizedBox(height: 18),
              _reminderSection(context, remindersState),
              const SizedBox(height: 18),
              _attachmentSection(context, attachmentsState),
              const SizedBox(height: 18),
              _notesSection(context, task, timeFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(8),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const Spacer(),
        Text(
          'TASK DETAILS',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).subduedText,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(8),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref
                  .read(
                      taskAttachmentControllerProvider(widget.taskId).notifier)
                  .load();
              ref
                  .read(taskReminderControllerProvider(widget.taskId).notifier)
                  .load();
              ref
                  .read(taskSubtaskControllerProvider(widget.taskId).notifier)
                  .load();
              ref
                  .read(taskTagControllerProvider(widget.taskId).notifier)
                  .load();
              ref.read(tagControllerProvider.notifier).load();
            },
          ),
        ),
      ],
    );
  }

  Widget _heroCard(
    BuildContext context,
    TaskViewModel task,
    List<TagItem> assignedTags,
    UserTimeFormat timeFormat,
  ) {
    final tagLabel = assignedTags.isNotEmpty
        ? assignedTags.map((e) => e.name).join(' • ')
        : (task.tags.isEmpty ? 'General' : task.tags.join(' • '));

    return GlassContainer(
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tagLabel.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppPalette.teal, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill(
                context,
                icon: Icons.schedule_rounded,
                label: _taskWindowLabel(context, task, timeFormat),
                color: Theme.of(context).subduedText,
              ),
              const SizedBox(width: 10),
              _pill(
                context,
                icon: Icons.circle,
                label: _statusLabel(task.status),
                color: _statusColor(task.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskTagSection(
    BuildContext context,
    AsyncValue<List<TagItem>> taskTagsState,
    AsyncValue<List<TagItem>> allTagsState,
  ) {
    final assignedCount = taskTagsState.valueOrNull?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              '($assignedCount)',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).subduedText),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _busyTaskTags
                  ? null
                  : () => _editTaskTags(taskTagsState, allTagsState),
              icon: _busyTaskTags
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sell_rounded),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        taskTagsState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => GlassContainer(
            borderRadius: 20,
            child: Text(
              'Failed to load task tags: $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          data: (tags) {
            if (tags.isEmpty) {
              return GlassContainer(
                borderRadius: 20,
                child: Text(
                  'No tags assigned. Tap Manage to assign tags.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).subduedText),
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Chip(
                    avatar: const Icon(Icons.label_rounded, size: 16),
                    label: Text(tag.name),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _subtaskSection(
    BuildContext context,
    TaskViewModel task,
    AsyncValue<List<SubtaskItem>> subtasksState,
  ) {
    final subtasks = subtasksState.valueOrNull ?? const <SubtaskItem>[];
    final total = subtasks.length;
    final done = subtasks.where((item) => item.isDone).length;
    final visibleProgress = total > 0;
    final progress = visibleProgress ? (done / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Subtasks',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              '($total)',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).subduedText),
            ),
            const Spacer(),
            IconButton(
              onPressed: _busySubtasks ? null : _addSubtask,
              icon: _busySubtasks
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task_rounded, color: AppPalette.teal),
            ),
            if (visibleProgress) ...[
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppPalette.teal, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 3,
                  color: AppPalette.teal,
                  backgroundColor: Theme.of(context).isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.10),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        subtasksState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => GlassContainer(
            borderRadius: 20,
            child: Text(
              'Failed to load subtasks: $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return GlassContainer(
                borderRadius: 20,
                child: Text(
                  'No subtasks yet. Tap add to create one.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).subduedText),
                ),
              );
            }

            return Column(
              children: [
                for (final subtask in items) ...[
                  _SubtaskTile(
                    subtask: subtask,
                    onToggle: () => _toggleSubtask(subtask),
                    onEdit: () => _editSubtask(subtask),
                    onDelete: () => _deleteSubtask(subtask),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _reminderSection(
      BuildContext context, AsyncValue<List<ReminderItem>> remindersState) {
    final count = remindersState.valueOrNull?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reminders',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              '($count)',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).subduedText),
            ),
            const Spacer(),
            IconButton(
              onPressed: _busyReminders ? null : _addReminder,
              icon: _busyReminders
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_alert_rounded, color: AppPalette.teal),
            ),
          ],
        ),
        const SizedBox(height: 10),
        remindersState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => GlassContainer(
            borderRadius: 20,
            child: Text(
              'Failed to load reminders: $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          data: (reminders) {
            if (reminders.isEmpty) {
              return GlassContainer(
                borderRadius: 20,
                child: Text(
                  'No reminders. Tap the bell-plus icon to add one.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).subduedText),
                ),
              );
            }

            return Column(
              children: [
                for (final reminder in reminders) ...[
                  _ReminderTile(
                    reminder: reminder,
                    onEdit: () => _editReminder(reminder),
                    onDelete: () => _deleteReminder(reminder),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _attachmentSection(
      BuildContext context, AsyncValue<List<AttachmentItem>> attachmentsState) {
    final attachments =
        attachmentsState.valueOrNull ?? const <AttachmentItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              '(${attachments.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).subduedText),
            ),
            const Spacer(),
            IconButton(
              onPressed: _busyAttachments ? null : _addAttachment,
              icon: _busyAttachments
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded,
                      color: AppPalette.teal),
            ),
          ],
        ),
        const SizedBox(height: 10),
        attachmentsState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => GlassContainer(
            borderRadius: 20,
            child: Text(
              'Failed to load attachments: $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return GlassContainer(
                borderRadius: 20,
                child: Text(
                  'No attachments yet. Tap paperclip to upload image/PDF.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).subduedText),
                ),
              );
            }
            return SizedBox(
              height: 182,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _AttachmentCard(
                    attachment: item,
                    onDelete: () => _deleteAttachment(item),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _notesSection(
    BuildContext context,
    TaskViewModel task,
    UserTimeFormat timeFormat,
  ) {
    return GlassContainer(
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: Theme.of(context).subduedText),
              const SizedBox(width: 8),
              Text(
                'NOTES',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).subduedText,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Task ID: ${task.id}\n\n'
            'Status: ${_statusLabel(task.status)}\n'
            'Window: ${_taskWindowLabel(context, task, timeFormat)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _editTaskTags(
    AsyncValue<List<TagItem>> taskTagsState,
    AsyncValue<List<TagItem>> allTagsState,
  ) async {
    final allTags = allTagsState.valueOrNull;
    if (allTags == null) {
      _snack('Tags are still loading. Try again.');
      return;
    }
    if (allTags.isEmpty) {
      _snack('No tags exist. Create tags from Settings > Tags first.');
      return;
    }

    final initialSelected = {
      for (final tag in (taskTagsState.valueOrNull ?? const <TagItem>[])) tag.id
    };
    var draft = <String>{...initialSelected};

    final selected = await showModalBottomSheet<Set<String>?>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.sell_rounded, color: AppPalette.teal),
                      title: Text('Assign Tags to Task'),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final tag in allTags)
                            CheckboxListTile(
                              value: draft.contains(tag.id),
                              title: Text(tag.name),
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    draft.add(tag.id);
                                  } else {
                                    draft.remove(tag.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(draft),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;
    setState(() => _busyTaskTags = true);
    try {
      await ref
          .read(taskTagControllerProvider(widget.taskId).notifier)
          .replaceTagIds(selected.toList());
      _snack('Task tags updated');
    } catch (error) {
      _snack('Could not update task tags: $error');
    } finally {
      if (mounted) setState(() => _busyTaskTags = false);
    }
  }

  Future<void> _addSubtask() async {
    final draft = await _showSubtaskEditor();
    if (draft == null) return;

    setState(() => _busySubtasks = true);
    try {
      await ref
          .read(taskSubtaskControllerProvider(widget.taskId).notifier)
          .createSubtask(title: draft.title, note: draft.note);
      _snack('Subtask added');
    } catch (error) {
      _snack('Failed to add subtask: $error');
    } finally {
      if (mounted) setState(() => _busySubtasks = false);
    }
  }

  Future<void> _toggleSubtask(SubtaskItem subtask) async {
    try {
      await ref
          .read(taskSubtaskControllerProvider(widget.taskId).notifier)
          .updateSubtask(
            subtaskId: subtask.id,
            isDone: !subtask.isDone,
          );
    } catch (error) {
      _snack('Failed to update subtask: $error');
    }
  }

  Future<void> _editSubtask(SubtaskItem subtask) async {
    final draft = await _showSubtaskEditor(
      initialTitle: subtask.title,
      initialNote: subtask.note,
      isEdit: true,
    );
    if (draft == null) return;

    try {
      await ref
          .read(taskSubtaskControllerProvider(widget.taskId).notifier)
          .updateSubtask(
            subtaskId: subtask.id,
            title: draft.title,
            note: draft.note,
          );
      _snack('Subtask updated');
    } catch (error) {
      _snack('Failed to update subtask: $error');
    }
  }

  Future<void> _deleteSubtask(SubtaskItem subtask) async {
    try {
      await ref
          .read(taskSubtaskControllerProvider(widget.taskId).notifier)
          .deleteSubtask(subtask.id);
      _snack('Subtask deleted');
    } catch (error) {
      _snack('Failed to delete subtask: $error');
    }
  }

  Future<_SubtaskDraft?> _showSubtaskEditor({
    String? initialTitle,
    String? initialNote,
    bool isEdit = false,
  }) async {
    return showDialog<_SubtaskDraft?>(
      context: context,
      builder: (context) {
        return _SubtaskEditorDialog(
          initialTitle: initialTitle,
          initialNote: initialNote,
          isEdit: isEdit,
        );
      },
    );
  }

  Future<void> _addAttachment() async {
    setState(() => _busyAttachments = true);
    try {
      await ref
          .read(taskAttachmentControllerProvider(widget.taskId).notifier)
          .addFromPicker();
      _snack('Attachment uploaded');
    } catch (error) {
      _snack('Upload failed: $error');
    } finally {
      if (mounted) setState(() => _busyAttachments = false);
    }
  }

  Future<void> _deleteAttachment(AttachmentItem attachment) async {
    try {
      await ref
          .read(taskAttachmentControllerProvider(widget.taskId).notifier)
          .deleteAttachment(attachment.id);
      _snack('Attachment deleted');
    } catch (error) {
      _snack('Delete failed: $error');
    }
  }

  Future<void> _addReminder() async {
    final reminderDefaults =
        ref.read(userPreferencesProvider).valueOrNull?.reminderDefaults;
    final options =
        reminderDefaults?.quickOptions ?? const <int>[5, 10, 15, 30, 60];
    final selected = await showModalBottomSheet<int?>(
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
                  leading:
                      Icon(Icons.alarm_add_rounded, color: AppPalette.teal),
                  title: Text('Add Reminder'),
                ),
                for (final offset in options)
                  ListTile(
                    title: Text('$offset min before start'),
                    subtitle: offset == reminderDefaults?.defaultRelativeMin
                        ? const Text('Default')
                        : null,
                    onTap: () => Navigator.of(context).pop(offset),
                  ),
                ListTile(
                  title: const Text('Pick absolute date/time'),
                  onTap: () => Navigator.of(context).pop(-1),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    if (!mounted) return;
    setState(() => _busyReminders = true);
    final controller =
        ref.read(taskReminderControllerProvider(widget.taskId).notifier);
    try {
      if (selected == -1) {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: DateTime(now.year + 4),
        );
        if (date == null) return;
        if (!mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        final local = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        await controller.createAbsolute(local.toUtc());
      } else {
        await controller.createRelative(selected);
      }
      _snack('Reminder saved');
    } catch (error) {
      _snack('Reminder save failed: $error');
    } finally {
      if (mounted) setState(() => _busyReminders = false);
    }
  }

  Future<void> _editReminder(ReminderItem reminder) async {
    if (!reminder.isRelative) {
      _snack('Absolute reminders can be recreated if needed.');
      return;
    }
    final ctrl = TextEditingController(
      text: (reminder.offsetMinFromTaskStart ?? 15).toString(),
    );
    final nextValue = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reminder'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              suffixText: 'min before',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(int.tryParse(ctrl.text)),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (nextValue == null || nextValue <= 0) return;
    try {
      await ref
          .read(taskReminderControllerProvider(widget.taskId).notifier)
          .updateRelative(
            reminderId: reminder.id,
            offsetMinFromTaskStart: nextValue,
          );
      _snack('Reminder updated');
    } catch (error) {
      _snack('Reminder update failed: $error');
    }
  }

  Future<void> _deleteReminder(ReminderItem reminder) async {
    try {
      await ref
          .read(taskReminderControllerProvider(widget.taskId).notifier)
          .deleteReminder(reminder.id);
      _snack('Reminder deleted');
    } catch (error) {
      _snack('Reminder delete failed: $error');
    }
  }

  String _taskWindowLabel(
    BuildContext context,
    TaskViewModel task,
    UserTimeFormat timeFormat,
  ) {
    return '${formatMinutesForPreference(context, task.startMin, timeFormat)} - ${formatMinutesForPreference(context, task.endMin, timeFormat)}';
  }

  String _statusLabel(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => 'To Do',
      TaskStatus.inProgress => 'In Progress',
      TaskStatus.blocked => 'Blocked',
      TaskStatus.done => 'Done',
    };
  }

  Color _statusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => AppPalette.teal,
      TaskStatus.inProgress => AppPalette.success,
      TaskStatus.blocked => AppPalette.danger,
      TaskStatus.done => AppPalette.success,
    };
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _SubtaskDraft {
  const _SubtaskDraft({
    required this.title,
    this.note,
  });

  final String title;
  final String? note;
}

class _SubtaskEditorDialog extends StatefulWidget {
  const _SubtaskEditorDialog({
    required this.isEdit,
    this.initialTitle,
    this.initialNote,
  });

  final bool isEdit;
  final String? initialTitle;
  final String? initialNote;

  @override
  State<_SubtaskEditorDialog> createState() => _SubtaskEditorDialogState();
}

class _SubtaskEditorDialogState extends State<_SubtaskEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _noteCtrl = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.isEdit ? 'Edit Subtask' : 'Add Subtask'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Subtask title',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            final note = _noteCtrl.text.trim();
            Navigator.of(context).pop(
              _SubtaskDraft(
                title: title,
                note: note.isEmpty ? null : note,
              ),
            );
          },
          child: Text(widget.isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  const _SubtaskTile({
    required this.subtask,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final SubtaskItem subtask;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = subtask.isDone;
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppPalette.teal : Colors.transparent,
                border: Border.all(
                  color: done ? AppPalette.teal : Theme.of(context).subduedText,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF032A27))
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done
                            ? Theme.of(context).subduedText
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (subtask.note != null && subtask.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtask.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).subduedText),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppPalette.danger),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  final ReminderItem reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = reminder.isRelative
        ? '${reminder.offsetMinFromTaskStart} min before start'
        : _absoluteLabel(reminder.triggerAtUtc);
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: AppPalette.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppPalette.danger),
          ),
        ],
      ),
    );
  }

  String _absoluteLabel(DateTime? dt) {
    if (dt == null) return 'Absolute time';
    final local = dt.toLocal();
    final hour =
        local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '$hour:$minute $suffix';
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.onDelete,
  });

  final AttachmentItem attachment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPdf = attachment.isPdf;

    return SizedBox(
      width: 176,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: isPdf
                        ? [const Color(0xFF2B1A1C), const Color(0xFF1A2328)]
                        : [const Color(0xFF5D8E82), const Color(0xFF2E5A56)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.image_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppPalette.danger.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatSize(attachment.size),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
