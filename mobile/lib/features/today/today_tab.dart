import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/time_format.dart';
import '../../core/models/app_models.dart';
import '../../core/models/user_preferences.dart';
import '../../core/providers/day_mode_provider.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../core/providers/subtask_provider.dart';
import '../../core/providers/user_preferences_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/sync_status_chip.dart';
import '../../shared/widgets/task_card.dart';

class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final selectedDay = DateTime(now.year, now.month, now.day);
    final mode = ref.watch(dayModeProvider);
    final tasks = ref.watch(taskListProvider);
    final holidayMap = ref.watch(holidayDatesProvider);
    final prefs = ref.watch(userPreferencesProvider).valueOrNull;

    final holidays = holidayMap[selectedDay] ?? [];
    final hideTasksOnHolidays =
        prefs?.holidayPrefs.hideTasksOnHolidays ?? false;
    final dayTasks = (hideTasksOnHolidays && holidays.isNotEmpty)
        ? <TaskViewModel>[]
        : tasks.where((task) => _sameDay(task.dateLocal, selectedDay)).toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    final completed =
        dayTasks.where((task) => task.status == TaskStatus.done).length;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 146),
            children: [
              _Header(selectedDay: selectedDay),
              const SizedBox(height: 10),
              const Align(
                  alignment: Alignment.centerRight, child: SyncStatusChip()),
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatChip(
                        icon: Icons.task_alt,
                        label: 'Total',
                        value: '${dayTasks.length} Tasks'),
                    const SizedBox(width: 10),
                    _StatChip(
                        icon: Icons.check_circle,
                        label: 'Done',
                        value: '$completed Tasks',
                        tint: AppPalette.success),
                    if (holidays.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.celebration,
                        label: 'Holiday',
                        value: holidays.first.name.toUpperCase(),
                        tint: AppPalette.danger,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ModeToggle(
                mode: mode,
                onChanged: (next) {
                  HapticFeedback.selectionClick();
                  ref.read(dayModeProvider.notifier).state = next;
                },
              ),
              if (holidays.isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(14),
                  tint: Theme.of(context).isDark
                      ? AppPalette.danger.withValues(alpha: 0.10)
                      : AppPalette.danger.withValues(alpha: 0.17),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppPalette.danger.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.beach_access_rounded,
                            color: AppPalette.danger),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Holiday: ${holidays.map((e) => e.name).join(', ')}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.danger,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: mode == DayMode.agenda
                    ? _AgendaList(
                        tasks: dayTasks,
                        onToggleComplete: (task) =>
                            _toggleTaskCompletion(context, ref, task),
                      )
                    : _TimelineList(tasks: dayTasks),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _toggleTaskCompletion(
    BuildContext context,
    WidgetRef ref,
    TaskViewModel task,
  ) async {
    final markDone = task.status != TaskStatus.done;
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
      if (!context.mounted) return;
      HapticFeedback.mediumImpact();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppPalette.teal,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              ),
              Text(
                '${_weekday(selectedDay)}, ${_month(selectedDay)} ${selectedDay.day}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).subduedText,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        GlassContainer(
          borderRadius: 40,
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.notifications_rounded,
              color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  String _weekday(DateTime day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day.weekday - 1];
  }

  String _month(DateTime day) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[day.month - 1];
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.tint = AppPalette.teal,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Theme.of(context).subduedText)),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final DayMode mode;
  final ValueChanged<DayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).isDark;

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(5),
      tint: dark
          ? const Color.fromRGBO(5, 14, 13, 0.48)
          : const Color.fromRGBO(222, 238, 238, 0.55),
      child: Row(
        children: [
          Expanded(
            child: _ToggleItem(
              title: 'Agenda',
              selected: mode == DayMode.agenda,
              onTap: () => onChanged(DayMode.agenda),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ToggleItem(
              title: 'Timeline',
              selected: mode == DayMode.timeline,
              onTap: () => onChanged(DayMode.timeline),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem(
      {required this.title, required this.selected, required this.onTap});

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppPalette.teal : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: AppPalette.teal.withValues(alpha: 0.36),
                    blurRadius: 14,
                    spreadRadius: 0.2)
              ]
            : const [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected
                        ? const Color(0xFF022624)
                        : Theme.of(context).subduedText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.tasks,
    required this.onToggleComplete,
  });

  final List<TaskViewModel> tasks;
  final Future<void> Function(TaskViewModel task) onToggleComplete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return GlassContainer(
        borderRadius: 22,
        child: Text('No tasks for this day',
            style: Theme.of(context).textTheme.titleMedium),
      );
    }

    return Column(
      key: const ValueKey('agenda'),
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          TaskCard(
            task: tasks[i],
            onToggleComplete: () => onToggleComplete(tasks[i]),
          )
              .animate(delay: (i * 65).ms)
              .fadeIn(duration: 260.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.tasks});

  final List<TaskViewModel> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return GlassContainer(
        borderRadius: 22,
        child: Text('No tasks in timeline',
            style: Theme.of(context).textTheme.titleMedium),
      );
    }

    return Column(
      key: const ValueKey('timeline'),
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          _TimelineCard(task: tasks[i])
              .animate(delay: (i * 70).ms)
              .fadeIn(duration: 260.ms)
              .slideX(begin: 0.06, end: 0),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.task});

  final TaskViewModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = ref
            .watch(userPreferencesProvider)
            .valueOrNull
            ?.calendarPrefs
            .timeFormat ??
        UserTimeFormat.system;
    final subtasksState = ref.watch(taskSubtaskControllerProvider(task.id));
    final subtasks = subtasksState.valueOrNull;
    final totalSubtasks = subtasks?.length ?? task.totalSubtasks;
    final doneSubtasks = subtasks?.where((subtask) => subtask.isDone).length ??
        task.doneSubtasks;
    final hasSubtasks = totalSubtasks > 0;
    final progressPercent =
        hasSubtasks ? (doneSubtasks / totalSubtasks) * 100 : 0.0;
    final isDone = task.status == TaskStatus.done;

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      tint: theme.taskCardTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    formatMinutesForPreference(
                        context, task.startMin, timeFormat),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.subduedText)),
                const SizedBox(height: 28),
                Container(width: 1, height: 26, color: theme.dividerColor),
                const SizedBox(height: 8),
                Text(
                    formatMinutesForPreference(
                        context, task.endMin, timeFormat),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.subduedText)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, fontSize: 37 / 2)),
                const SizedBox(height: 4),
                Text(
                  task.hasAttachment
                      ? 'Includes attachment preview'
                      : 'Focused work block',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.subduedText),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleComplete(context, ref, task),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isDone ? AppPalette.success : theme.subduedText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppPalette.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppPalette.teal.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        task.status.name.toUpperCase(),
                        style: const TextStyle(
                            color: AppPalette.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (task.hasAttachment)
                      Row(
                        children: [
                          Icon(Icons.attach_file_rounded,
                              size: 16, color: theme.subduedText),
                          Text(' files',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.subduedText)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasSubtasks)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressPercent / 100,
                      strokeWidth: 4,
                      color: AppPalette.teal,
                      backgroundColor: theme.isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    Text(
                      '$doneSubtasks/$totalSubtasks',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: AppPalette.teal, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    TaskViewModel task,
  ) async {
    final markDone = task.status != TaskStatus.done;
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
      HapticFeedback.mediumImpact();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    }
  }
}
