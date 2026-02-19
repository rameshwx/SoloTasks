import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_models.dart';
import '../../core/models/remote_models.dart';
import '../../core/providers/day_mode_provider.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../core/providers/tag_provider.dart';
import '../../core/providers/task_tag_provider.dart';
import '../../core/providers/user_preferences_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/glass_container.dart';
import '../tasks/tag_manager_sheet.dart';

class QuickAddTaskSheet extends ConsumerStatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  ConsumerState<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends ConsumerState<QuickAddTaskSheet> {
  final _titleCtrl = TextEditingController();
  Set<String> _selectedTagIds = <String>{};

  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    final startMinutes = ((now.hour * 60 + now.minute + 14) ~/ 15) * 15;
    final endMinutes = (startMinutes + 60).clamp(15, 1439);
    _start = TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
    _end = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final holidayMap = ref.watch(holidayDatesProvider);
    final tagsState = ref.watch(tagControllerProvider);
    final prefs = ref.watch(userPreferencesProvider).valueOrNull;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final holidays = holidayMap[selectedDay] ?? const [];
    final showHolidayWarning =
        prefs?.holidayPrefs.warnWhenSchedulingOnHoliday ?? true;
    final selectedTagNames = (tagsState.valueOrNull ?? const <TagItem>[])
        .where((tag) => _selectedTagIds.contains(tag.id))
        .map((tag) => tag.name)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + viewInsets.bottom),
      child: GlassContainer(
        borderRadius: 28,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        tint: Theme.of(context).isDark
            ? const Color.fromRGBO(8, 22, 21, 0.90)
            : const Color.fromRGBO(244, 251, 250, 0.94),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    color: AppPalette.teal),
                const SizedBox(width: 8),
                Text(
                  'Quick Add Task',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Date: ${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).subduedText,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Task title',
                prefixIcon: Icon(Icons.task_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTagNames.isEmpty
                        ? 'No tags selected'
                        : selectedTagNames.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selectedTagNames.isEmpty
                              ? Theme.of(context).subduedText
                              : null,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : () => _selectTags(tagsState),
                  icon: const Icon(Icons.sell_rounded),
                  label: const Text('Select Tags'),
                ),
                TextButton(
                  onPressed: _saving ? null : _openTagManager,
                  child: const Text('Manage'),
                ),
              ],
            ),
            if (selectedTagNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final name in selectedTagNames)
                    Chip(
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timeTile(
                    label: 'Start',
                    value: _start.format(context),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _start,
                      );
                      if (picked != null) {
                        setState(() => _start = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeTile(
                    label: 'End',
                    value: _end.format(context),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _end,
                      );
                      if (picked != null) {
                        setState(() => _end = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.teal,
                  foregroundColor: const Color(0xFF032A27),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                onPressed: _saving
                    ? null
                    : () => _save(
                          selectedDay,
                          selectedTagNames: selectedTagNames,
                          selectedTagIds: _selectedTagIds.toList(),
                          holidays: holidays,
                          showHolidayWarning: showHolidayWarning,
                        ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving...' : 'Create Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: Theme.of(context).subduedText,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: AppPalette.teal),
                const SizedBox(width: 6),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    DateTime selectedDay, {
    required List<String> selectedTagNames,
    required List<String> selectedTagIds,
    required List<HolidayType> holidays,
    required bool showHolidayWarning,
  }) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;

    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    if (showHolidayWarning && holidays.isNotEmpty) {
      final names = holidays.map((h) => h.name).join(', ');
      final proceed = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Schedule on holiday?'),
                content: Text(
                    'This day has holiday type(s): $names.\nDo you want to continue?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Continue'),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!proceed) return;
    }

    setState(() => _saving = true);
    try {
      final createdTask =
          await ref.read(taskListProvider.notifier).addQuickTask(
                title: title,
                dateLocal: selectedDay,
                startMin: startMin,
                endMin: endMin,
                tags: selectedTagNames,
              );
      await ref
          .read(taskTagControllerProvider(createdTask.id).notifier)
          .replaceTagIds(selectedTagIds);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $error')),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _openTagManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TagManagerSheet(),
    );
    if (!mounted) return;
    await ref.read(tagControllerProvider.notifier).load();
  }

  Future<void> _selectTags(AsyncValue<List<TagItem>> tagsState) async {
    final tags = tagsState.valueOrNull;
    if (tags == null || tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No tags yet. Use Manage to create tags.')),
      );
      return;
    }

    var draft = <String>{..._selectedTagIds};
    final selected = await showModalBottomSheet<Set<String>?>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      title: Text('Select Tags'),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final tag in tags)
                            CheckboxListTile(
                              value: draft.contains(tag.id),
                              title: Text(tag.name),
                              onChanged: (checked) {
                                setModalState(() {
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
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;
    setState(() => _selectedTagIds = selected);
  }
}
