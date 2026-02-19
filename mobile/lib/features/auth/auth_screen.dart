import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SoloTasks', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with Email OTP',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  if (_otpSent)
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'OTP (6 digits)'),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _otpSent ? _verifyOtp : _requestOtp,
                    icon: Icon(_otpSent ? Icons.lock_open : Icons.email_outlined),
                    label: Text(_otpSent ? 'Verify OTP' : 'Request OTP'),
                  ),
                  if (_otpSent)
                    TextButton(
                      onPressed: _cooldown > 0 ? null : _requestOtp,
                      child: Text(_cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend OTP'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestOtp() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _otpSent = true;
      _cooldown = 60;
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
