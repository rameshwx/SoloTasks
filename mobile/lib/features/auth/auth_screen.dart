import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpSent = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    _buildBrand(theme),
                    const SizedBox(height: 20),
                    GlassContainer(
                      borderRadius: 36,
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
                      tint: isDark
                          ? const Color.fromRGBO(9, 24, 22, 0.68)
                          : const Color.fromRGBO(247, 252, 252, 0.74),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _otpSent
                                ? 'Enter Verification Code'
                                : 'Welcome Back',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _otpSent
                                ? 'Type the one-time password sent to your email.'
                                : 'Enter your email to sign in and access your workspace.',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.subduedText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _otpSent ? 'ONE-TIME PASSWORD' : 'EMAIL ADDRESS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppPalette.teal,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _otpSent ? _otpCtrl : _emailCtrl,
                            keyboardType: _otpSent
                                ? TextInputType.number
                                : TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            maxLength: _otpSent ? 6 : null,
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon: Icon(_otpSent
                                  ? Icons.password_rounded
                                  : Icons.mail_outline_rounded),
                              hintText: _otpSent
                                  ? '6-digit code'
                                  : 'name@example.com',
                            ),
                            onSubmitted: (_) =>
                                _otpSent ? _verifyOtp() : _requestOtp(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppPalette.teal,
                                foregroundColor: const Color(0xFF072B28),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 20),
                                shadowColor:
                                    AppPalette.teal.withValues(alpha: 0.45),
                              ),
                              onPressed: _otpSent ? _verifyOtp : _requestOtp,
                              icon: Icon(_otpSent
                                  ? Icons.lock_open_rounded
                                  : Icons.arrow_forward_rounded),
                              label: Text(_otpSent
                                  ? 'Verify OTP'
                                  : 'Send One-Time Password'),
                            ).animate(target: _otpSent ? 1 : 0).shimmer(
                                duration: 950.ms,
                                color: Colors.white.withValues(alpha: 0.38)),
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _cooldown == 0 ? _requestOtp : null,
                                child: Text(_cooldown == 0
                                    ? 'Resend OTP'
                                    : 'Resend in ${_cooldown}s'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Divider(color: theme.dividerColor),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: theme.subduedText, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Code valid for 5 minutes. Check your spam folder if code does not arrive.',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.subduedText),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Privacy Policy      Terms of Service',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.subduedText),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand(ThemeData theme) {
    return Column(
      children: [
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(14),
          tint: theme.isDark
              ? const Color.fromRGBO(13, 242, 223, 0.10)
              : const Color.fromRGBO(13, 242, 223, 0.16),
          child: const Icon(Icons.calendar_month_rounded,
              color: AppPalette.teal, size: 34),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
                begin: const Offset(0.98, 0.98),
                end: const Offset(1.02, 1.02),
                duration: 2.1.seconds),
        const SizedBox(height: 14),
        Text(
          'CHRONOS',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Future<void> _requestOtp() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _otpSent = true;
      _cooldown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown == 0) {
        timer.cancel();
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length < 4) return;
    await ref.read(authControllerProvider.notifier).loginWithOtp(
          accessToken: 'demo-access',
          refreshToken: 'demo-refresh',
        );
  }
}
