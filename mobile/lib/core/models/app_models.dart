enum TaskStatus { todo, inProgress, blocked, done }

enum HolidayType { bank, public, mercantile }

enum DayMode { agenda, timeline }

class TaskViewModel {
  TaskViewModel({
    required this.id,
    required this.title,
    required this.status,
    required this.dateLocal,
    required this.startMin,
    required this.endMin,
    required this.tags,
    required this.totalSubtasks,
    required this.doneSubtasks,
    required this.hasAttachment,
  });

  final String id;
  final String title;
  final TaskStatus status;
  final DateTime dateLocal;
  final int startMin;
  final int endMin;
  final List<String> tags;
  final int totalSubtasks;
  final int doneSubtasks;
  final bool hasAttachment;

  bool get hasSubtasks => totalSubtasks > 0;
  double? get progressPercent {
    if (totalSubtasks == 0) return null;
    return (doneSubtasks / totalSubtasks) * 100;
  }
}
