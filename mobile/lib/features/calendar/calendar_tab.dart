import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models/app_models.dart';
import '../../core/providers/day_mode_provider.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../shared/widgets/task_card.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final mode = ref.watch(dayModeProvider);
    final tasks = ref.watch(taskListProvider);
    final holidayMap = ref.watch(holidayDatesProvider);

    final dayTasks = tasks.where((task) {
      return task.dateLocal.year == selectedDay.year &&
          task.dateLocal.month == selectedDay.month &&
          task.dateLocal.day == selectedDay.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2035, 12, 31),
                focusedDay: selectedDay,
                calendarFormat: _format,
                selectedDayPredicate: (day) => _sameDay(day, selectedDay),
                onDaySelected: (selected, _) {
                  ref.read(selectedDayProvider.notifier).state = DateTime(selected.year, selected.month, selected.day);
                },
                onFormatChanged: (format) => setState(() => _format = format),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final types = holidayMap[DateTime(day.year, day.month, day.day)];
                    if (types == null || types.isEmpty) return null;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('${day.day}')),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<DayMode>(
            segments: const [
              ButtonSegment(value: DayMode.agenda, label: Text('Agenda')),
              ButtonSegment(value: DayMode.timeline, label: Text('Timeline')),
            ],
            selected: {mode},
            onSelectionChanged: (selection) {
              ref.read(dayModeProvider.notifier).state = selection.first;
            },
          ),
          const SizedBox(height: 12),
          if (holidayMap[selectedDay] case final types?)
            Card(
              child: ListTile(
                title: Text('Holiday: ${types.map((e) => e.name).join(', ')}'),
                subtitle: const Text('Scheduling is allowed, warning setting can be enabled.'),
              ),
            ),
          const SizedBox(height: 12),
          for (final task in dayTasks) ...[
            TaskCard(task: task),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
