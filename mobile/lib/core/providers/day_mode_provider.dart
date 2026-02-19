import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

final selectedDayProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dayModeProvider = StateProvider<DayMode>((_) => DayMode.agenda);
