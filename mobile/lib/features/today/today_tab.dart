import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_models.dart';
import '../../core/providers/day_mode_provider.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../shared/widgets/sync_status_chip.dart';
import '../../shared/widgets/task_card.dart';

class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final mode = ref.watch(dayModeProvider);
    final tasks = ref.watch(taskListProvider);
    final holidayMap = ref.watch(holidayDatesProvider);
    final holidays = holidayMap[selectedDay] ?? [];

    final dayTasks = tasks.where((task) => _sameDay(task.dateLocal, selectedDay)).toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusChip(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick add flow placeholder (date + time required)')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Card(
            child: ListTile(
              title: Text('${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}'),
              subtitle: const Text('Selected day'),
              trailing: SegmentedButton<DayMode>(
                segments: const [
                  ButtonSegment(value: DayMode.agenda, label: Text('Agenda')),
                  ButtonSegment(value: DayMode.timeline, label: Text('Timeline')),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  ref.read(dayModeProvider.notifier).state = selection.first;
                },
              ),
            ),
          ),
          if (holidays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Holiday: ${holidays.map((e) => e.name).join(', ')}'),
            ),
          ],
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: mode == DayMode.agenda
                ? _AgendaList(tasks: dayTasks)
                : _TimelineList(tasks: dayTasks),
          ),
        ],
      ).animate().fadeIn(duration: 220.ms),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.tasks});

  final List<TaskViewModel> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No tasks for this day'),
      );
    }

    return Column(
      key: const ValueKey('agenda'),
      children: [
        for (final task in tasks) ...[
          TaskCard(task: task),
          const SizedBox(height: 10),
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
    return Column(
      key: const ValueKey('timeline'),
      children: [
        for (final task in tasks) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.drag_indicator),
              title: Text(task.title),
              subtitle: Text('Drag to reschedule placeholder'),
              trailing: const Icon(Icons.schedule),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
