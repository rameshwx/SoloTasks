import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.isDark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF021413), Color(0xFF082423), Color(0xFF041918)]
              : const [Color(0xFFE7F8F6), Color(0xFFDBECEE), Color(0xFFF5FBFB)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -80,
            child: _glow(const Size(300, 300),
                AppPalette.teal.withValues(alpha: dark ? 0.20 : 0.16)),
          ),
          Positioned(
            bottom: -130,
            right: -80,
            child: _glow(const Size(280, 280),
                AppPalette.success.withValues(alpha: dark ? 0.14 : 0.10)),
          ),
          Positioned(
            top: 180,
            right: -20,
            child: _glow(const Size(180, 180),
                AppPalette.teal.withValues(alpha: dark ? 0.10 : 0.08)),
          ),
          if (padding != null)
            Padding(
              padding: padding!,
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }

  Widget _glow(Size size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 120,
              spreadRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
