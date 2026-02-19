import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/providers/user_preferences_provider.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../tasks/tag_manager_sheet.dart';
import 'holidays/holidays_settings_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final prefsState = ref.watch(userPreferencesProvider);
    final prefs = prefsState.valueOrNull ??
        UserPreferences.defaults(weekStart: WeekStart.sunday);

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 146),
            children: [
              Text('Settings',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              GlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _tile(
                      context,
                      icon: Icons.celebration_outlined,
                      title: 'Holidays',
                      subtitle: 'Manage Bank / Public / Mercantile holidays',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const HolidaysSettingsScreen()),
                        );
                      },
                    ),
                    _tile(
                      context,
                      icon: Icons.sell_rounded,
                      title: 'Tags',
                      subtitle: 'Create / rename / delete tags',
                      onTap: () => _openTagManager(context),
                    ),
                    _reminderDefaultsTile(context, ref, prefs),
                    _weekStartTile(context, ref, prefs),
                    _timeFormatTile(context, ref, prefs),
                    SwitchListTile.adaptive(
                      value: prefs.holidayPrefs.warnWhenSchedulingOnHoliday,
                      onChanged: (enabled) {
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setWarnOnHoliday(enabled);
                      },
                      title: const Text('Warn when scheduling on holiday'),
                    ),
                    SwitchListTile.adaptive(
                      value: prefs.holidayPrefs.hideTasksOnHolidays,
                      onChanged: (enabled) {
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setHideTasksOnHolidays(enabled);
                      },
                      title: const Text('Hide tasks on holidays'),
                    ),
                    SwitchListTile.adaptive(
                      value: themeMode == ThemeMode.light,
                      onChanged: (enabled) {
                        ref.read(themeModeProvider.notifier).state =
                            enabled ? ThemeMode.light : ThemeMode.dark;
                      },
                      title: const Text('Use Light Theme'),
                      subtitle: const Text('Toggle dark / light mode'),
                    ),
                    _tile(
                      context,
                      icon: Icons.logout,
                      title: 'Log out',
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminderDefaultsTile(
    BuildContext context,
    WidgetRef ref,
    UserPreferences prefs,
  ) {
    final selected = prefs.reminderDefaults.defaultRelativeMin;
    return ListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: const Text('Reminder defaults'),
      subtitle: const Text('Default reminder offset for new reminders'),
      trailing: DropdownButton<int>(
        value: selected,
        items: prefs.reminderDefaults.quickOptions
            .map(
              (minute) => DropdownMenuItem<int>(
                value: minute,
                child: Text('$minute min'),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next == null) return;
          ref
              .read(userPreferencesProvider.notifier)
              .setReminderDefaultMinutes(next);
        },
      ),
    );
  }

  Widget _weekStartTile(
    BuildContext context,
    WidgetRef ref,
    UserPreferences prefs,
  ) {
    return ListTile(
      leading: const Icon(Icons.calendar_view_week_outlined),
      title: const Text('Week start'),
      trailing: DropdownButton<WeekStart>(
        value: prefs.calendarPrefs.weekStart,
        items: const [
          DropdownMenuItem(value: WeekStart.sunday, child: Text('Sunday')),
          DropdownMenuItem(value: WeekStart.monday, child: Text('Monday')),
        ],
        onChanged: (next) {
          if (next == null) return;
          ref.read(userPreferencesProvider.notifier).setWeekStart(next);
        },
      ),
    );
  }

  Widget _timeFormatTile(
    BuildContext context,
    WidgetRef ref,
    UserPreferences prefs,
  ) {
    return ListTile(
      leading: const Icon(Icons.schedule_outlined),
      title: const Text('Time format'),
      trailing: DropdownButton<UserTimeFormat>(
        value: prefs.calendarPrefs.timeFormat,
        items: const [
          DropdownMenuItem(value: UserTimeFormat.system, child: Text('System')),
          DropdownMenuItem(value: UserTimeFormat.h12, child: Text('12h')),
          DropdownMenuItem(value: UserTimeFormat.h24, child: Text('24h')),
        ],
        onChanged: (next) {
          if (next == null) return;
          ref.read(userPreferencesProvider.notifier).setTimeFormat(next);
        },
      ),
    );
  }

  Future<void> _openTagManager(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TagManagerSheet(),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
