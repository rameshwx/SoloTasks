import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

final taskListProvider = StateProvider<List<TaskViewModel>>((_) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    TaskViewModel(
      id: '1',
      title: 'Plan Sprint Goals',
      status: TaskStatus.inProgress,
      dateLocal: today,
      startMin: 540,
      endMin: 600,
      tags: ['work', 'planning'],
      totalSubtasks: 3,
      doneSubtasks: 1,
      hasAttachment: true,
    ),
    TaskViewModel(
      id: '2',
      title: 'Read architecture docs',
      status: TaskStatus.todo,
      dateLocal: today,
      startMin: 690,
      endMin: 750,
      tags: ['deep-work'],
      totalSubtasks: 0,
      doneSubtasks: 0,
      hasAttachment: false,
    ),
  ];
});

final holidayDatesProvider = StateProvider<Map<DateTime, List<HolidayType>>>((_) {
  final now = DateTime.now();
  return {
    DateTime(now.year, now.month, now.day): [HolidayType.public],
  };
});
