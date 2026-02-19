import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/remote_models.dart';
import '../../core/providers/tag_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/glass_container.dart';

class TagManagerSheet extends ConsumerStatefulWidget {
  const TagManagerSheet({super.key});

  @override
  ConsumerState<TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends ConsumerState<TagManagerSheet> {
  final _newTagCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
      child: GlassContainer(
        borderRadius: 26,
        tint: Theme.of(context).isDark
            ? const Color.fromRGBO(8, 22, 21, 0.9)
            : const Color.fromRGBO(246, 252, 252, 0.92),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: SizedBox(
          height: 460,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.sell_rounded, color: AppPalette.teal),
                  const SizedBox(width: 8),
                  Text(
                    'Tag Manager',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Create a new tag',
                        prefixIcon: Icon(Icons.add_circle_outline_rounded),
                      ),
                      onSubmitted: (_) => _createTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _creating ? null : _createTag,
                    child: Text(_creating ? '...' : 'Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: tagsState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorBlock(
                    text: 'Failed to load tags: $error',
                    onRetry: () =>
                        ref.read(tagControllerProvider.notifier).load(),
                  ),
                  data: (tags) {
                    if (tags.isEmpty) {
                      return const Center(
                        child: Text('No tags yet'),
                      );
                    }
                    return ListView.separated(
                      itemCount: tags.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return _TagTile(
                          tag: tag,
                          onRename: () => _renameTag(tag),
                          onDelete: () => _deleteTag(tag),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    final text = _newTagCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _creating = true);
    try {
      await ref.read(tagControllerProvider.notifier).createTag(text);
      _newTagCtrl.clear();
      HapticFeedback.lightImpact();
    } catch (error) {
      _snack('Could not create tag: $error');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _renameTag(TagItem tag) async {
    final ctrl = TextEditingController(text: tag.name);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Tag'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Tag name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (updated == null || updated.isEmpty || updated == tag.name) return;
    try {
      await ref.read(tagControllerProvider.notifier).renameTag(tag.id, updated);
    } catch (error) {
      _snack('Could not rename tag: $error');
    }
  }

  Future<void> _deleteTag(TagItem tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Tag'),
          content: Text('Delete "${tag.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppPalette.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ref.read(tagControllerProvider.notifier).deleteTag(tag.id);
      HapticFeedback.selectionClick();
    } catch (error) {
      _snack('Could not delete tag: $error');
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.tag,
    required this.onRename,
    required this.onDelete,
  });

  final TagItem tag;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.label_rounded, color: AppPalette.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tag.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onRename,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppPalette.danger),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
