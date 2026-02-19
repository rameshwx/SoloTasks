import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint ?? theme.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: theme.glassBorder),
            boxShadow: [
              if (theme.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
