import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_models.dart';
import '../../core/models/remote_models.dart';
import '../../core/providers/mock_data_provider.dart';
import '../../core/providers/tag_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'tag_manager_sheet.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  final _searchCtrl = TextEditingController();

  bool _hasAttachments = false;
  String? _selectedTagName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final tagsState = ref.watch(tagControllerProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(query);
      final matchesAttachment = !_hasAttachments || task.hasAttachment;
      final matchesTag = _selectedTagName == null
          ? true
          : task.tags.any((tag) => tag == _selectedTagName);
      return matchesSearch && matchesAttachment && matchesTag;
    }).toList();

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 146),
            children: [
              _header(context),
              const SizedBox(height: 14),
              _filterRow(context, tagsState),
              const SizedBox(height: 18),
              _smartListHeader(context),
              const SizedBox(height: 10),
              _smartLists(context),
              const SizedBox(height: 20),
              Text(
                'Recent Results',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < filtered.length; i++) ...[
                _ResultTaskTile(task: filtered[i])
                    .animate(delay: (i * 55).ms)
                    .fadeIn(duration: 240.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return GlassContainer(
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Tasks',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              GlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.person, color: AppPalette.teal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search tasks, events, tags...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _searchCtrl.clear()),
                icon: const Icon(Icons.mic_none_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(BuildContext context, AsyncValue<List<TagItem>> tagsState) {
    final tagLabel =
        _selectedTagName == null ? 'Tags' : 'Tag: $_selectedTagName';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipBtn(title: 'Status', onTap: () {}),
          const SizedBox(width: 10),
          _FilterChipBtn(
            title: tagLabel,
            onTap: () => _openTagPicker(tagsState),
          ),
          if (_selectedTagName != null) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => setState(() => _selectedTagName = null),
              icon: const Icon(Icons.clear_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(width: 10),
          _FilterChipBtn(title: 'Date Range', onTap: () {}),
          const SizedBox(width: 10),
          _FilterChipBtn(
            title: _hasAttachments ? 'Attachments: On' : 'Attachments',
            trailing: _hasAttachments
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            onTap: () => setState(() => _hasAttachments = !_hasAttachments),
          ),
        ],
      ),
    );
  }

  Widget _smartListHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Smart Lists',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        TextButton(
            onPressed: _openTagManager, child: const Text('Manage Tags')),
      ],
    );
  }

  Widget _smartLists(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmartListCard(
            icon: Icons.work,
            iconColor: AppPalette.success,
            title: 'Work',
            subtitle: 'Next 7 Days',
            count: '12',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmartListCard(
            icon: Icons.block,
            iconColor: AppPalette.danger,
            title: 'Blocked',
            subtitle: 'Requires Action',
            count: '3',
          ),
        ),
      ],
    );
  }

  Future<void> _openTagManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TagManagerSheet(),
    );
  }

  Future<void> _openTagPicker(AsyncValue<List<TagItem>> tagsState) async {
    final tags = tagsState.valueOrNull;
    if (tags == null || tags.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No tags yet. Use Manage Tags to add one.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text('Filter by Tag'),
                  leading: Icon(Icons.sell_rounded, color: AppPalette.teal),
                ),
                ListTile(
                  title: const Text('All Tags'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
                for (final tag in tags)
                  ListTile(
                    title: Text(tag.name),
                    onTap: () => Navigator.of(context).pop(tag.name),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _selectedTagName = selected);
  }
}

class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({
    required this.title,
    this.trailing = Icons.expand_more,
    required this.onTap,
  });

  final String title;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Icon(trailing, size: 18, color: Theme.of(context).subduedText),
          ],
        ),
      ),
    );
  }
}

class _SmartListCard extends StatelessWidget {
  const _SmartListCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String count;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              Text(count,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 18),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 35 / 2)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).subduedText)),
        ],
      ),
    );
  }
}

class _ResultTaskTile extends StatelessWidget {
  const _ResultTaskTile({required this.task});

  final TaskViewModel task;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked,
              color: Color(0xFF738B96), size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: Theme.of(context).subduedText),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(task.startMin),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: task.status == TaskStatus.blocked
                                ? AppPalette.danger
                                : AppPalette.teal,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Theme.of(context).subduedText,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Icon(Icons.folder_outlined,
                        size: 16, color: Theme.of(context).subduedText),
                    const SizedBox(width: 4),
                    Text(task.tags.isEmpty ? 'General' : task.tags.first,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Theme.of(context).subduedText)),
                  ],
                ),
              ],
            ),
          ),
          if (task.hasAttachment)
            Icon(Icons.attach_file_rounded,
                color: Theme.of(context).subduedText)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: AppPalette.success.withValues(alpha: 0.35)),
              ),
              child: const Text('Finance',
                  style: TextStyle(
                      color: AppPalette.success, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  String _formatTime(int totalMin) {
    final hour = totalMin ~/ 60;
    final minute = totalMin % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return 'Today ${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }
}
