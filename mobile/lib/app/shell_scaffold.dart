import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_palette.dart';
import '../features/calendar/calendar_tab.dart';
import '../features/settings/settings_tab.dart';
import '../features/tasks/tasks_tab.dart';
import '../features/today/quick_add_task_sheet.dart';
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
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: _pages[_index],
        ),
      ).animate().fadeIn(duration: 220.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _GlowAddButton(
        onPressed: _openQuickAddSheet,
      ),
      bottomNavigationBar: _BottomGlassNav(
        currentIndex: _index,
        onChanged: (next) {
          HapticFeedback.selectionClick();
          setState(() => _index = next);
        },
      ),
    );
  }

  Future<void> _openQuickAddSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddTaskSheet(),
    );
  }
}

class _BottomGlassNav extends StatelessWidget {
  const _BottomGlassNav({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: theme.isDark
                    ? const Color.fromRGBO(12, 25, 24, 0.82)
                    : const Color.fromRGBO(236, 245, 247, 0.84),
                border: Border.all(color: theme.glassBorder),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.wb_sunny_outlined,
                      activeIcon: Icons.wb_sunny,
                      label: 'Today',
                      active: currentIndex == 0,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month,
                      label: 'Calendar',
                      active: currentIndex == 1,
                      onTap: () => onChanged(1),
                    ),
                  ),
                  const SizedBox(width: 82),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.task_alt_outlined,
                      activeIcon: Icons.task_alt,
                      label: 'Tasks',
                      active: currentIndex == 2,
                      onTap: () => onChanged(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                      active: currentIndex == 3,
                      onTap: () => onChanged(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppPalette.teal;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? accent : theme.subduedText,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? accent : theme.subduedText,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: active ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowAddButton extends StatelessWidget {
  const _GlowAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppPalette.teal.withValues(alpha: 0.55),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          FloatingActionButton(
            heroTag: 'shell-add-fab',
            onPressed: onPressed,
            backgroundColor: AppPalette.teal,
            foregroundColor: const Color(0xFF052624),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 36),
          ),
        ],
      ),
    );
  }
}
