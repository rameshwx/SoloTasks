import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/drift/app_database.dart';
import '../models/user_preferences.dart';
import '../services/authed_api_service.dart';
import 'api_provider.dart';
import 'database_provider.dart';

final userPreferencesProvider = StateNotifierProvider<UserPreferencesController,
    AsyncValue<UserPreferences>>(
  (ref) => UserPreferencesController(ref),
);

class UserPreferencesController
    extends StateNotifier<AsyncValue<UserPreferences>> {
  UserPreferencesController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  static const _settingsKey = 'user_preferences';

  final Ref _ref;

  Future<void> load() async {
    final local = await _loadLocalOrDefaults();
    state = AsyncValue.data(local);

    try {
      final remote =
          await _ref.read(authedApiServiceProvider).run((accessToken) async {
        final response = await _ref
            .read(apiClientProvider)
            .getPreferences(accessToken: accessToken);
        return UserPreferences.fromJson(_asMap(response.data));
      });
      state = AsyncValue.data(remote);
      await _saveLocal(remote);
    } catch (_) {
      // Keep local state when network is unavailable.
    }
  }

  Future<void> setReminderDefaultMinutes(int minutes) async {
    await _update((current) {
      return current.copyWith(
        reminderDefaults:
            current.reminderDefaults.copyWith(defaultRelativeMin: minutes),
      );
    });
  }

  Future<void> setWeekStart(WeekStart weekStart) async {
    await _update((current) {
      return current.copyWith(
        calendarPrefs: current.calendarPrefs.copyWith(weekStart: weekStart),
      );
    });
  }

  Future<void> setTimeFormat(UserTimeFormat format) async {
    await _update((current) {
      return current.copyWith(
        calendarPrefs: current.calendarPrefs.copyWith(timeFormat: format),
      );
    });
  }

  Future<void> setWarnOnHoliday(bool value) async {
    await _update((current) {
      return current.copyWith(
        holidayPrefs:
            current.holidayPrefs.copyWith(warnWhenSchedulingOnHoliday: value),
      );
    });
  }

  Future<void> setHideTasksOnHolidays(bool value) async {
    await _update((current) {
      return current.copyWith(
        holidayPrefs: current.holidayPrefs.copyWith(hideTasksOnHolidays: value),
      );
    });
  }

  Future<void> _update(
      UserPreferences Function(UserPreferences) transform) async {
    final current = state.valueOrNull ?? await _loadLocalOrDefaults();
    final next = transform(current);
    state = AsyncValue.data(next);
    await _saveLocal(next);

    try {
      final saved =
          await _ref.read(authedApiServiceProvider).run((accessToken) async {
        final response = await _ref.read(apiClientProvider).putPreferences(
              accessToken: accessToken,
              payload: next.toJson()..remove('updatedAt'),
            );
        return UserPreferences.fromJson(_asMap(response.data));
      });
      state = AsyncValue.data(saved);
      await _saveLocal(saved);
    } catch (_) {
      // Keep optimistic local state; will resync later.
    }
  }

  Future<UserPreferences> _loadLocalOrDefaults() async {
    final db = _ref.read(appDatabaseProvider);
    final row = await (db.select(db.settings)
          ..where((tbl) => tbl.key.equals(_settingsKey)))
        .getSingleOrNull();
    if (row == null) {
      return UserPreferences.defaults(weekStart: _deviceWeekStart());
    }
    try {
      return UserPreferences.fromJsonString(row.valueJson);
    } catch (_) {
      return UserPreferences.defaults(weekStart: _deviceWeekStart());
    }
  }

  Future<void> _saveLocal(UserPreferences preferences) async {
    final db = _ref.read(appDatabaseProvider);
    await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value(_settingsKey),
            valueJson: Value(jsonEncode(preferences.toJson())),
          ),
        );
  }

  WeekStart _deviceWeekStart() {
    final locale = PlatformDispatcher.instance.locale;
    final sundayRegions = <String>{
      'US',
      'CA',
      'AU',
      'NZ',
      'PH',
      'JP',
    };
    return sundayRegions.contains(locale.countryCode?.toUpperCase())
        ? WeekStart.sunday
        : WeekStart.monday;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return const <String, dynamic>{};
  }
}
