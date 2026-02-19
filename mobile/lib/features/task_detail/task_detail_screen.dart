import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 128),
            children: [
              _header(context),
              const SizedBox(height: 14),
              _heroCard(context),
              const SizedBox(height: 18),
              _subtaskSection(context),
              const SizedBox(height: 18),
              _attachmentSection(context),
              const SizedBox(height: 18),
              _notesSection(context),
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
          padding: const EdgeInsets.all(8),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const Spacer(),
        Text(
          'TASK DETAILS',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).subduedText,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context) {
    return GlassContainer(
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESIGN SYSTEM',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppPalette.teal, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Audit & Update',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill(context,
                  icon: Icons.schedule_rounded,
                  label: 'Today, 4:00 PM',
                  color: Theme.of(context).subduedText),
              const SizedBox(width: 10),
              _pill(context,
                  icon: Icons.circle,
                  label: 'In Progress',
                  color: AppPalette.success),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(
                  radius: 12, backgroundColor: Color(0xFF0D2A37)),
              const SizedBox(width: 6),
              const CircleAvatar(
                  radius: 12, backgroundColor: Color(0xFF1E4A59)),
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                    child: Text('+2',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700))),
              ),
              const Spacer(),
              Text('Created by Alex M.',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subtaskSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Subtasks',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('60%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppPalette.teal, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: 0.6,
                strokeWidth: 3,
                color: AppPalette.teal,
                backgroundColor: Theme.of(context).isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            children: [
              _subtaskItem(context,
                  title: 'Typography scale review', completed: true),
              const SizedBox(height: 8),
              _subtaskItem(
                context,
                title: 'Review Color Palette',
                reminder: '15 min before',
                active: true,
              ),
              const SizedBox(height: 8),
              _subtaskItem(context, title: 'Component library sync'),
              const SizedBox(height: 8),
              _subtaskItem(context, title: 'Accessibility check'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attachmentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachments',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text('(3)',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).subduedText)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 176,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _AttachmentCard(title: 'UI Mockup_v2'),
              SizedBox(width: 10),
              _AttachmentCard(title: 'Moodboard'),
              SizedBox(width: 10),
              _AttachmentCard(title: 'Audit_Specs.pdf', pdf: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notesSection(BuildContext context) {
    return GlassContainer(
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: Theme.of(context).subduedText),
              const SizedBox(width: 8),
              Text(
                'NOTES',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).subduedText,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Task ID: $taskId\n\nFocus on contrast ratios for dark mode implementation. Ensure primary teal passes AA standards on dark gray backgrounds.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _subtaskItem(
    BuildContext context, {
    required String title,
    bool completed = false,
    bool active = false,
    String? reminder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? AppPalette.teal.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? AppPalette.teal.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? AppPalette.teal : Theme.of(context).subduedText,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                        color: completed ? Theme.of(context).subduedText : null,
                      ),
                ),
                if (reminder != null)
                  Text(
                    reminder,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppPalette.teal),
                  ),
              ],
            ),
          ),
          Icon(Icons.drag_handle_rounded, color: Theme.of(context).subduedText),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.title, this.pdf = false});

  final String title;
  final bool pdf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: pdf
                        ? [const Color(0xFF2B1A1C), const Color(0xFF1A2328)]
                        : [const Color(0xFF9CAAA2), const Color(0xFF6A6F70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            if (pdf)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppPalette.danger.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.picture_as_pdf,
                      color: AppPalette.danger),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
