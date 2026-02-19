import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

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

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final tasks = ref.watch(taskListProvider);
    final holidayMap = ref.watch(holidayDatesProvider);
    final selectedHolidays =
        holidayMap[_dayKey(selectedDay)] ?? const <HolidayType>[];
    final prefs = ref.watch(userPreferencesProvider).valueOrNull;
    final hideTasksOnHolidays =
        prefs?.holidayPrefs.hideTasksOnHolidays ?? false;

    final selectedTasks = tasks.where((task) {
      final sameDay = _dayKey(task.dateLocal) == _dayKey(selectedDay);
      if (!sameDay) return false;
      if (!hideTasksOnHolidays) return true;
      return (holidayMap[_dayKey(task.dateLocal)] ?? const []).isEmpty;
    }).toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 146),
            children: [
              _header(context),
              const SizedBox(height: 14),
              GlassContainer(
                borderRadius: 30,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  children: [
                    TableCalendar<TaskViewModel>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2038, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          _dayKey(day) == _dayKey(selectedDay),
                      headerVisible: false,
                      rowHeight: 54,
                      startingDayOfWeek: (prefs?.calendarPrefs.weekStart ??
                                  WeekStart.sunday) ==
                              WeekStart.monday
                          ? StartingDayOfWeek.monday
                          : StartingDayOfWeek.sunday,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      onDaySelected: (selected, focused) {
                        ref.read(selectedDayProvider.notifier).state = DateTime(
                            selected.year, selected.month, selected.day);
                        setState(() => _focusedDay = focused);
                      },
                      onPageChanged: (focused) =>
                          setState(() => _focusedDay = focused),
                      eventLoader: (day) {
                        return tasks
                            .where((task) =>
                                _dayKey(task.dateLocal) == _dayKey(day))
                            .toList();
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, _) => _dayBubble(
                          context: context,
                          day: day,
                          selected: false,
                          hasHoliday:
                              (holidayMap[_dayKey(day)] ?? const []).isNotEmpty,
                        ),
                        todayBuilder: (context, day, _) => _dayBubble(
                          context: context,
                          day: day,
                          selected: _dayKey(day) == _dayKey(selectedDay),
                          hasHoliday:
                              (holidayMap[_dayKey(day)] ?? const []).isNotEmpty,
                        ),
                        selectedBuilder: (context, day, _) => _dayBubble(
                          context: context,
                          day: day,
                          selected: true,
                          hasHoliday:
                              (holidayMap[_dayKey(day)] ?? const []).isNotEmpty,
                        ),
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          final count = events.length.clamp(1, 3);
                          return Padding(
                            padding: const EdgeInsets.only(top: 34),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < count; i++)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                        color: AppPalette.teal,
                                        shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
              if (selectedHolidays.isNotEmpty) ...[
                const SizedBox(height: 12),
                _holidayBanner(context, selectedHolidays),
              ],
              const SizedBox(height: 16),
              for (final task in selectedTasks) ...[
                TaskCard(
                  task: task,
                  onToggleComplete: () => _toggleTaskCompletion(task),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final day = _focusedDay;
    final month = _monthName(day.month);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CALENDAR',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).subduedText,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$month ${day.year}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.8),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more_rounded,
                      color: Theme.of(context).subduedText),
                ],
              ),
            ],
          ),
        ),
        const SyncStatusChip(),
      ],
    );
  }

  Widget _dayBubble({
    required BuildContext context,
    required DateTime day,
    required bool selected,
    required bool hasHoliday,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppPalette.teal.withValues(alpha: theme.isDark ? 0.20 : 0.24)
            : theme.isDark
                ? const Color.fromRGBO(255, 255, 255, 0.04)
                : const Color.fromRGBO(0, 0, 0, 0.04),
        border: Border.all(
          color: hasHoliday
              ? AppPalette.success.withValues(alpha: 0.6)
              : selected
                  ? AppPalette.teal.withValues(alpha: 0.55)
                  : theme.glassBorder,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppPalette.teal.withValues(alpha: 0.30),
                  blurRadius: 12,
                ),
              ]
            : const [],
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppPalette.teal : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _holidayBanner(BuildContext context, List<HolidayType> holidays) {
    final holidayNames = holidays
        .map((type) => '${type.name[0].toUpperCase()}${type.name.substring(1)}')
        .join(', ');

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      tint: Theme.of(context).isDark
          ? AppPalette.teal.withValues(alpha: 0.10)
          : AppPalette.teal.withValues(alpha: 0.17),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppPalette.teal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.beach_access_rounded, color: AppPalette.teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Holiday: $holidayNames',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month - 1];
  }

  Future<void> _toggleTaskCompletion(TaskViewModel task) async {
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
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    }
  }

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);
}
