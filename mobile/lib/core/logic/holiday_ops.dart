import '../models/app_models.dart';

Map<DateTime, List<HolidayType>> toggleHolidayType(
  Map<DateTime, List<HolidayType>> source,
  DateTime date,
  HolidayType type,
) {
  final key = DateTime(date.year, date.month, date.day);
  final copy = Map<DateTime, List<HolidayType>>.from(source);
  final existing = [...(copy[key] ?? <HolidayType>[])];

  if (existing.contains(type)) {
    existing.remove(type);
  } else {
    existing.add(type);
  }

  if (existing.isEmpty) {
    copy.remove(key);
  } else {
    copy[key] = existing;
  }

  return copy;
}

Map<DateTime, List<HolidayType>> clearTypeForYear(
  Map<DateTime, List<HolidayType>> source,
  int year,
  HolidayType type,
) {
  final out = <DateTime, List<HolidayType>>{};
  for (final entry in source.entries) {
    if (entry.key.year == year && entry.value.contains(type)) {
      final next = [...entry.value]..remove(type);
      if (next.isNotEmpty) out[entry.key] = next;
    } else {
      out[entry.key] = [...entry.value];
    }
  }
  return out;
}

Map<DateTime, List<HolidayType>> copyTypeFromPreviousYear(
  Map<DateTime, List<HolidayType>> source,
  int targetYear,
  HolidayType type,
) {
  final sourceYear = targetYear - 1;
  final out = <DateTime, List<HolidayType>>{
    for (final entry in source.entries) entry.key: [...entry.value],
  };

  for (final entry in source.entries) {
    if (entry.key.year != sourceYear || !entry.value.contains(type)) continue;
    final targetDate = DateTime(targetYear, entry.key.month, entry.key.day);
    final existing = [...(out[targetDate] ?? <HolidayType>[])];
    if (!existing.contains(type)) {
      existing.add(type);
      out[targetDate] = existing;
    }
  }

  return out;
}
