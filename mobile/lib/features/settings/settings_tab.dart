import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'export_import/export_import_screen.dart';
import 'holidays/holidays_settings_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
                      icon: Icons.file_download_outlined,
                      title: 'Export / Import',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ExportImportScreen()),
                        );
                      },
                    ),
                    _tile(context,
                        icon: Icons.notifications_active_outlined,
                        title: 'Reminder defaults'),
                    _tile(context,
                        icon: Icons.date_range_outlined,
                        title: 'Week start / time format'),
                    SwitchListTile.adaptive(
                      value: themeMode != ThemeMode.dark,
                      onChanged: (enabled) {
                        ref.read(themeModeProvider.notifier).state =
                            enabled ? ThemeMode.light : ThemeMode.dark;
                      },
                      title: const Text('Use Light Theme'),
                      subtitle: const Text('Toggle dark / light mode'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.brightness_auto_outlined),
                      title: const Text('Follow System Theme'),
                      trailing: TextButton(
                        onPressed: () => ref
                            .read(themeModeProvider.notifier)
                            .state = ThemeMode.system,
                        child: const Text('Auto'),
                      ),
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
