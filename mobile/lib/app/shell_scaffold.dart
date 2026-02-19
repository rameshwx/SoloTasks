import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../features/calendar/calendar_tab.dart';
import '../features/settings/settings_tab.dart';
import '../features/tasks/tasks_tab.dart';
import '../features/today/today_tab.dart';

class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({super.key});

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  int _index = 0;

  final _pages = const [
    TodayTab(),
    CalendarTab(),
    TasksTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages)
          .animate()
          .fadeIn(duration: 250.ms, curve: Curves.easeOut),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
