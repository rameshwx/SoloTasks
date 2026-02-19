import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import 'export_import/export_import_screen.dart';
import 'holidays/holidays_settings_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.celebration_outlined),
                  title: const Text('Holidays'),
                  subtitle: const Text('Manage Bank / Public / Mercantile holidays'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HolidaysSettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export / Import'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ExportImportScreen()),
                    );
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Reminder defaults'),
                ),
                const ListTile(
                  leading: Icon(Icons.color_lens_outlined),
                  title: Text('Theme'),
                ),
                const ListTile(
                  leading: Icon(Icons.date_range_outlined),
                  title: Text('Week start / time format'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  onTap: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
