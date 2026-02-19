import 'dart:convert';

enum WeekStart { sunday, monday }

enum UserTimeFormat { system, h12, h24 }

class ReminderDefaults {
  const ReminderDefaults({
    required this.defaultRelativeMin,
    required this.quickOptions,
    required this.autoCreate,
  });

  final int defaultRelativeMin;
  final List<int> quickOptions;
  final bool autoCreate;

  factory ReminderDefaults.defaults() {
    return const ReminderDefaults(
      defaultRelativeMin: 15,
      quickOptions: <int>[5, 10, 15, 30, 60],
      autoCreate: false,
    );
  }

  factory ReminderDefaults.fromJson(Map<String, dynamic> json) {
    final rawList = json['quickOptions'];
    final list = rawList is List
        ? rawList
            .map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList()
        : <int>[5, 10, 15, 30, 60];
    return ReminderDefaults(
      defaultRelativeMin:
          int.tryParse('${json['defaultRelativeMin'] ?? 15}') ?? 15,
      quickOptions: list.isEmpty ? const <int>[5, 10, 15, 30, 60] : list,
      autoCreate: json['autoCreate'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'defaultRelativeMin': defaultRelativeMin,
        'quickOptions': quickOptions,
        'autoCreate': autoCreate,
      };

  ReminderDefaults copyWith({
    int? defaultRelativeMin,
    List<int>? quickOptions,
    bool? autoCreate,
  }) {
    return ReminderDefaults(
      defaultRelativeMin: defaultRelativeMin ?? this.defaultRelativeMin,
      quickOptions: quickOptions ?? this.quickOptions,
      autoCreate: autoCreate ?? this.autoCreate,
    );
  }
}

class CalendarPrefs {
  const CalendarPrefs({
    required this.weekStart,
    required this.timeFormat,
  });

  final WeekStart weekStart;
  final UserTimeFormat timeFormat;

  factory CalendarPrefs.defaults({
    required WeekStart weekStart,
  }) {
    return CalendarPrefs(
      weekStart: weekStart,
      timeFormat: UserTimeFormat.system,
    );
  }

  factory CalendarPrefs.fromJson(Map<String, dynamic> json) {
    final weekStartRaw = (json['weekStart'] ?? 'sunday').toString();
    final timeFormatRaw = (json['timeFormat'] ?? 'system').toString();
    return CalendarPrefs(
      weekStart: weekStartRaw == 'monday' ? WeekStart.monday : WeekStart.sunday,
      timeFormat: switch (timeFormatRaw) {
        '12h' => UserTimeFormat.h12,
        '24h' => UserTimeFormat.h24,
        _ => UserTimeFormat.system,
      },
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'weekStart': weekStart == WeekStart.monday ? 'monday' : 'sunday',
        'timeFormat': switch (timeFormat) {
          UserTimeFormat.h12 => '12h',
          UserTimeFormat.h24 => '24h',
          UserTimeFormat.system => 'system',
        },
      };

  CalendarPrefs copyWith({
    WeekStart? weekStart,
    UserTimeFormat? timeFormat,
  }) {
    return CalendarPrefs(
      weekStart: weekStart ?? this.weekStart,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}

class HolidayPrefs {
  const HolidayPrefs({
    required this.warnWhenSchedulingOnHoliday,
    required this.hideTasksOnHolidays,
  });

  final bool warnWhenSchedulingOnHoliday;
  final bool hideTasksOnHolidays;

  factory HolidayPrefs.defaults() {
    return const HolidayPrefs(
      warnWhenSchedulingOnHoliday: true,
      hideTasksOnHolidays: false,
    );
  }

  factory HolidayPrefs.fromJson(Map<String, dynamic> json) {
    return HolidayPrefs(
      warnWhenSchedulingOnHoliday: json['warnWhenSchedulingOnHoliday'] != false,
      hideTasksOnHolidays: json['hideTasksOnHolidays'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'warnWhenSchedulingOnHoliday': warnWhenSchedulingOnHoliday,
        'hideTasksOnHolidays': hideTasksOnHolidays,
      };

  HolidayPrefs copyWith({
    bool? warnWhenSchedulingOnHoliday,
    bool? hideTasksOnHolidays,
  }) {
    return HolidayPrefs(
      warnWhenSchedulingOnHoliday:
          warnWhenSchedulingOnHoliday ?? this.warnWhenSchedulingOnHoliday,
      hideTasksOnHolidays: hideTasksOnHolidays ?? this.hideTasksOnHolidays,
    );
  }
}

class UserPreferences {
  const UserPreferences({
    required this.reminderDefaults,
    required this.calendarPrefs,
    required this.holidayPrefs,
    this.updatedAt,
  });

  final ReminderDefaults reminderDefaults;
  final CalendarPrefs calendarPrefs;
  final HolidayPrefs holidayPrefs;
  final DateTime? updatedAt;

  factory UserPreferences.defaults({required WeekStart weekStart}) {
    return UserPreferences(
      reminderDefaults: ReminderDefaults.defaults(),
      calendarPrefs: CalendarPrefs.defaults(weekStart: weekStart),
      holidayPrefs: HolidayPrefs.defaults(),
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      reminderDefaults:
          ReminderDefaults.fromJson(_toMap(json['reminderDefaults'])),
      calendarPrefs: CalendarPrefs.fromJson(_toMap(json['calendarPrefs'])),
      holidayPrefs: HolidayPrefs.fromJson(_toMap(json['holidayPrefs'])),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }

  factory UserPreferences.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return UserPreferences.fromJson(decoded);
    }
    if (decoded is Map) {
      return UserPreferences.fromJson(decoded.cast<String, dynamic>());
    }
    throw const FormatException('Invalid user preferences JSON');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reminderDefaults': reminderDefaults.toJson(),
        'calendarPrefs': calendarPrefs.toJson(),
        'holidayPrefs': holidayPrefs.toJson(),
        if (updatedAt != null)
          'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  UserPreferences copyWith({
    ReminderDefaults? reminderDefaults,
    CalendarPrefs? calendarPrefs,
    HolidayPrefs? holidayPrefs,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      reminderDefaults: reminderDefaults ?? this.reminderDefaults,
      calendarPrefs: calendarPrefs ?? this.calendarPrefs,
      holidayPrefs: holidayPrefs ?? this.holidayPrefs,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}
