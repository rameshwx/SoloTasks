import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/user_preferences.dart';
import '../../../core/providers/mock_data_provider.dart';
import '../../../core/providers/user_preferences_provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/glass_container.dart';

class HolidaysSettingsScreen extends ConsumerStatefulWidget {
  const HolidaysSettingsScreen({super.key});

  @override
  ConsumerState<HolidaysSettingsScreen> createState() =>
      _HolidaysSettingsScreenState();
}

class _HolidaysSettingsScreenState
    extends ConsumerState<HolidaysSettingsScreen> {
  late int _year;
  HolidayType _selectedType = HolidayType.public;
  Map<DateTime, List<HolidayType>> _draft = <DateTime, List<HolidayType>>{};
  bool _draftInitialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final holidayMap = _normalized(ref.watch(holidayDatesProvider));
    final weekStart = ref
            .watch(userPreferencesProvider)
            .valueOrNull
            ?.calendarPrefs
            .weekStart ??
        WeekStart.sunday;
    if (!_draftInitialized) {
      _draft = _normalized(holidayMap);
      _draftInitialized = true;
    }

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 190),
                children: [
                  _header(context),
                  const SizedBox(height: 12),
                  _typeSelector(context),
                  const SizedBox(height: 14),
                  _yearRow(context),
                  const SizedBox(height: 12),
                  for (var month = 1; month <= 12; month++) ...[
                    _monthCard(context, _draft, month, weekStart: weekStart),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 86,
                child: _bulkActionBar(context, _draft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const Spacer(),
        Text(
          'Holiday Settings',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? 'Saving...' : 'Save',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppPalette.teal),
          ),
        ),
      ],
    );
  }

  Widget _typeSelector(BuildContext context) {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (final type in HolidayType.values) ...[
            Expanded(
              child: _typeButton(context, type),
            ),
            if (type != HolidayType.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _typeButton(BuildContext context, HolidayType type) {
    final selected = type == _selectedType;
    final label = switch (type) {
      HolidayType.public => 'Public',
      HolidayType.bank => 'Bank',
      HolidayType.mercantile => 'Mercantile',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? AppPalette.teal : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppPalette.teal.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ]
            : const [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _selectedType = type),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF032B28)
                        : Theme.of(context).subduedText,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _yearRow(BuildContext context) {
    return Row(
      children: [
        Text('$_year',
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        _circleBtn(
            context, Icons.chevron_left_rounded, () => setState(() => _year--)),
        const SizedBox(width: 8),
        _circleBtn(context, Icons.chevron_right_rounded,
            () => setState(() => _year++)),
      ],
    );
  }

  Widget _circleBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return GlassContainer(
      borderRadius: 40,
      padding: const EdgeInsets.all(4),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Theme.of(context).subduedText),
      ),
    );
  }

  Widget _monthCard(BuildContext context,
      Map<DateTime, List<HolidayType>> holidayMap, int month,
      {required WeekStart weekStart}) {
    final focused = DateTime(_year, month, 1);

    return GlassContainer(
      borderRadius: 34,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              _monthName(month),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          TableCalendar<void>(
            firstDay: DateTime(_year, 1, 1),
            lastDay: DateTime(_year, 12, 31),
            focusedDay: focused,
            daysOfWeekVisible: true,
            availableGestures: AvailableGestures.none,
            rowHeight: 44,
            startingDayOfWeek: weekStart == WeekStart.monday
                ? StartingDayOfWeek.monday
                : StartingDayOfWeek.sunday,
            headerVisible: false,
            selectedDayPredicate: (day) {
              final types = holidayMap[_key(day)] ?? const <HolidayType>[];
              return types.contains(_selectedType);
            },
            onDaySelected: (selected, _) {
              final key = _key(selected);
              final map = Map<DateTime, List<HolidayType>>.from(holidayMap);
              final current = [...(map[key] ?? <HolidayType>[])];
              if (current.contains(_selectedType)) {
                current.remove(_selectedType);
              } else {
                current.add(_selectedType);
              }

              if (current.isEmpty) {
                map.remove(key);
              } else {
                map[key] = current;
              }
              setState(() => _draft = _normalized(map));
            },
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text =
                    ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day.weekday % 7];
                return Center(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Theme.of(context).subduedText),
                  ),
                );
              },
              selectedBuilder: (context, day, _) =>
                  _holidayDayCircle(context, day.day, selected: true),
              defaultBuilder: (context, day, _) {
                if (day.month != month) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .subduedText
                              .withValues(alpha: 0.32)),
                    ),
                  );
                }
                return _holidayDayCircle(context, day.day, selected: false);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _holidayDayCircle(BuildContext context, int day,
      {required bool selected}) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? AppPalette.teal : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppPalette.teal.withValues(alpha: 0.45),
                    blurRadius: 16,
                  ),
                ]
              : const [],
        ),
        child: Center(
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF032725) : null,
                ),
          ),
        ),
      ),
    );
  }

  Widget _bulkActionBar(
      BuildContext context, Map<DateTime, List<HolidayType>> holidayMap) {
    return GlassContainer(
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                final cleared = <DateTime, List<HolidayType>>{};
                for (final entry in holidayMap.entries) {
                  final updated = [...entry.value]..remove(_selectedType);
                  if (updated.isNotEmpty || entry.key.year != _year) {
                    if (entry.key.year == _year) {
                      if (updated.isNotEmpty) cleared[entry.key] = updated;
                    } else {
                      cleared[entry.key] = entry.value;
                    }
                  }
                }
                setState(() => _draft = _normalized(cleared));
              },
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppPalette.danger),
              label: const Text('CLEAR',
                  style: TextStyle(
                      color: AppPalette.danger, fontWeight: FontWeight.w800)),
            ),
          ),
          Container(
              width: 1, height: 48, color: Theme.of(context).dividerColor),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                final sourceYear = _year - 1;
                final map = Map<DateTime, List<HolidayType>>.from(holidayMap);
                final source = holidayMap.entries.where((entry) {
                  return entry.key.year == sourceYear &&
                      entry.value.contains(_selectedType);
                });
                for (final entry in source) {
                  final targetKey =
                      DateTime(_year, entry.key.month, entry.key.day);
                  final existing = [...(map[targetKey] ?? <HolidayType>[])];
                  if (!existing.contains(_selectedType)) {
                    existing.add(_selectedType);
                  }
                  map[targetKey] = existing;
                }
                setState(() => _draft = _normalized(map));
              },
              icon: const Icon(Icons.content_copy_rounded,
                  color: AppPalette.teal),
              label: Text('COPY ${_year - 1}',
                  style: const TextStyle(
                      color: AppPalette.teal, fontWeight: FontWeight.w800)),
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

  DateTime _key(DateTime day) => DateTime(day.year, day.month, day.day);

  Map<DateTime, List<HolidayType>> _normalized(
      Map<DateTime, List<HolidayType>> source) {
    return {
      for (final entry in source.entries) _key(entry.key): [...entry.value],
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(holidayDatesProvider.notifier).saveAll(_draft);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save holidays: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
