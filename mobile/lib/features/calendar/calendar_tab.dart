import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models/app_models.dart';
import '../../core/providers/day_mode_provider.dart';
import '../../core/providers/mock_data_provider.dart';
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

    final selectedTasks = tasks.where((task) {
      return _dayKey(task.dateLocal) == _dayKey(selectedDay);
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
                      startingDayOfWeek: StartingDayOfWeek.sunday,
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
                    const SizedBox(height: 8),
                    SegmentedButton<DayMode>(
                      segments: const [
                        ButtonSegment(
                            value: DayMode.agenda, label: Text('Agenda')),
                        ButtonSegment(
                            value: DayMode.timeline, label: Text('Timeline')),
                      ],
                      selected: {ref.watch(dayModeProvider)},
                      onSelectionChanged: (selection) {
                        ref.read(dayModeProvider.notifier).state =
                            selection.first;
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 18),
              Text(
                'Upcoming Highlights',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 32 / 2),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 136,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _highlightCard(context,
                        title: 'Independence Day',
                        subtitle: 'Sept 15 • All Day',
                        type: 'Holiday',
                        accent: AppPalette.success),
                    const SizedBox(width: 12),
                    _highlightCard(context,
                        title: 'Project Review',
                        subtitle: 'Sept 18 • 10:00 AM',
                        type: 'Work',
                        accent: AppPalette.teal),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final task in selectedTasks) ...[
                TaskCard(task: task),
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

  Widget _highlightCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String type,
    required Color accent,
  }) {
    return SizedBox(
      width: 196,
      child: GlassContainer(
        borderRadius: 26,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(type,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).subduedText)),
          ],
        ),
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

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);
}
