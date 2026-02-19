import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/app_models.dart';
import '../../../core/providers/mock_data_provider.dart';

class HolidaysSettingsScreen extends ConsumerStatefulWidget {
  const HolidaysSettingsScreen({super.key});

  @override
  ConsumerState<HolidaysSettingsScreen> createState() => _HolidaysSettingsScreenState();
}

class _HolidaysSettingsScreenState extends ConsumerState<HolidaysSettingsScreen> {
  late int _year;
  HolidayType _selectedType = HolidayType.bank;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final holidayMap = ref.watch(holidayDatesProvider);
    final normalized = _normalizeMap(holidayMap);

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              DropdownButton<int>(
                value: _year,
                items: [for (var y = _year - 2; y <= _year + 2; y++) DropdownMenuItem(value: y, child: Text('$y'))],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _year = value);
                },
              ),
              const SizedBox(width: 16),
              SegmentedButton<HolidayType>(
                segments: const [
                  ButtonSegment(value: HolidayType.bank, label: Text('Bank')),
                  ButtonSegment(value: HolidayType.public, label: Text('Public')),
                  ButtonSegment(value: HolidayType.mercantile, label: Text('Mercantile')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) => setState(() => _selectedType = selection.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime(_year, 1, 1),
                lastDay: DateTime(_year, 12, 31),
                focusedDay: _focusedDay,
                onPageChanged: (day) => _focusedDay = day,
                selectedDayPredicate: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  final types = normalized[key] ?? <HolidayType>[];
                  return types.contains(_selectedType);
                },
                onDaySelected: (selected, _) {
                  final key = DateTime(selected.year, selected.month, selected.day);
                  final map = Map<DateTime, List<HolidayType>>.from(normalized);
                  final current = [...(map[key] ?? <HolidayType>[])];
                  if (current.contains(_selectedType)) {
                    current.remove(_selectedType);
                  } else {
                    current.add(_selectedType);
                  }
                  map[key] = current;
                  ref.read(holidayDatesProvider.notifier).state = map;
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () {
                  final cleared = Map<DateTime, List<HolidayType>>.from(normalized)
                    ..removeWhere((key, value) => key.year == _year && value.contains(_selectedType));
                  ref.read(holidayDatesProvider.notifier).state = cleared;
                },
                child: const Text('Clear type for year'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  final sourceYear = _year - 1;
                  final copy = Map<DateTime, List<HolidayType>>.from(normalized);
                  final previous = copy.entries.where((entry) {
                    return entry.key.year == sourceYear && entry.value.contains(_selectedType);
                  });
                  for (final entry in previous) {
                    final target = DateTime(_year, entry.key.month, entry.key.day);
                    final existing = [...(copy[target] ?? <HolidayType>[])];
                    if (!existing.contains(_selectedType)) existing.add(_selectedType);
                    copy[target] = existing;
                  }
                  ref.read(holidayDatesProvider.notifier).state = copy;
                },
                child: const Text('Copy previous year'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<HolidayType>> _normalizeMap(Map<DateTime, List<HolidayType>> source) {
    return {
      for (final entry in source.entries)
        DateTime(entry.key.year, entry.key.month, entry.key.day): entry.value,
    };
  }
}
